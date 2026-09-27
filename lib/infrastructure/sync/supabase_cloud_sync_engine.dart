import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trail_path/core/config/cloud_config.dart';
import 'package:trail_path/core/database/app_database.dart';
import 'package:trail_path/core/domain/cloud_sync.dart';
import 'package:trail_path/core/services/account_service.dart';
import 'package:trail_path/core/services/cloud_sync_engine.dart';

class SupabaseCloudSyncEngine implements CloudSyncEngine {
  SupabaseCloudSyncEngine({
    required AppDatabase database,
    required AccountService accountService,
    SupabaseClient? client,
  }) : _database = database,
       _accountService = accountService,
       _client = client;

  static const String _table = 'trailpath_sync_items';

  final AppDatabase _database;
  final AccountService _accountService;
  final SupabaseClient? _client;

  @override
  bool get isConfigured => CloudConfig.isConfigured && _client != null;

  @override
  Future<CloudSyncSnapshot> syncNow() async {
    if (!isConfigured) {
      return CloudSyncSnapshot(
        phase: CloudSyncPhase.unavailable,
        isConfigured: false,
        pendingChanges: await _database.pendingSyncCount(),
      );
    }

    try {
      final client = _client!;
      final user = await _ensureUser(client);
      if (user == null) {
        return CloudSyncSnapshot(
          phase: CloudSyncPhase.unavailable,
          isConfigured: true,
          pendingChanges: await _database.pendingSyncCount(),
          error: 'Sign in with Google before enabling cloud sync.',
        );
      }

      await _database.ensureInitialSyncOutbox();

      var remote = await _fetchRemote(client, user.id);
      final mutations = await _database.listSyncMutations();

      for (final mutation in mutations) {
        final key = _key(mutation.entityType, mutation.entityId);
        final currentRemote = remote[key];
        final remoteStamp = currentRemote?.lastModified;

        if (remoteStamp != null &&
            remoteStamp.isAfter(mutation.updatedAt.toUtc())) {
          await _database.acknowledgeSyncMutation(mutation.id);
          continue;
        }

        final payload = mutation.action == SyncMutationAction.delete
            ? null
            : await _payloadFor(mutation);

        await client.from(_table).upsert(
          <String, Object?>{
            'user_id': user.id,
            'entity_type': mutation.entityType.name,
            'entity_id': mutation.entityId,
            'updated_at': mutation.updatedAt.toUtc().toIso8601String(),
            'deleted_at': mutation.action == SyncMutationAction.delete
                ? mutation.updatedAt.toUtc().toIso8601String()
                : null,
            'payload': payload,
          },
          onConflict: 'user_id,entity_type,entity_id',
        );
        await _database.acknowledgeSyncMutation(mutation.id);
      }

      remote = await _fetchRemote(client, user.id);
      for (final item in remote.values) {
        final localStamp = await _database.localSyncTimestamp(
          item.entityType,
          item.entityId,
        );

        if (item.deletedAt case final deletedAt?) {
          if (localStamp == null || !localStamp.isAfter(deletedAt)) {
            await _database.applyRemoteDelete(
              item.entityType,
              item.entityId,
            );
          }
          continue;
        }

        final payload = item.payload;
        if (payload == null) {
          continue;
        }
        if (localStamp != null && !item.updatedAt.isAfter(localStamp)) {
          continue;
        }

        switch (item.entityType) {
          case SyncEntityType.route:
            await _database.applyRemoteRoute(payload);
            break;
          case SyncEntityType.activity:
            await _database.applyRemoteActivity(payload);
            break;
          case SyncEntityType.preferences:
            await _database.applyRemotePreferences(payload, item.updatedAt);
            break;
        }
      }

      final now = DateTime.now().toUtc();
      await _database.setSetting(
        'last_cloud_sync_at',
        now.toIso8601String(),
      );

      return CloudSyncSnapshot(
        phase: CloudSyncPhase.success,
        isConfigured: true,
        lastSyncedAt: now,
        pendingChanges: await _database.pendingSyncCount(),
      );
    } on Object catch (error) {
      return CloudSyncSnapshot(
        phase: CloudSyncPhase.error,
        isConfigured: isConfigured,
        pendingChanges: await _database.pendingSyncCount(),
        error: error.toString(),
      );
    }
  }

  Future<User?> _ensureUser(SupabaseClient client) async {
    final existing = client.auth.currentUser;
    if (existing != null) {
      return existing;
    }

    final tokens = await _accountService.authTokens();
    if (tokens == null) {
      return null;
    }

    final response = await client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: tokens.idToken,
      accessToken: tokens.accessToken,
    );
    return response.user;
  }

  Future<Map<String, _RemoteSyncItem>> _fetchRemote(
    SupabaseClient client,
    String userId,
  ) async {
    final rows = await client
        .from(_table)
        .select()
        .eq('user_id', userId);

    final result = <String, _RemoteSyncItem>{};
    for (final raw in rows) {
      final item = _RemoteSyncItem.fromJson(
        Map<String, dynamic>.from(raw),
      );
      if (item != null) {
        result[_key(item.entityType, item.entityId)] = item;
      }
    }
    return result;
  }

  Future<Map<String, Object?>?> _payloadFor(SyncMutation mutation) {
    return switch (mutation.entityType) {
      SyncEntityType.route => _database.routeSyncPayload(mutation.entityId),
      SyncEntityType.activity =>
        _database.activitySyncPayload(mutation.entityId),
      SyncEntityType.preferences => _database.preferencesSyncPayload(),
    };
  }

  String _key(SyncEntityType type, String entityId) =>
      '${type.name}:$entityId';

  @override
  Future<void> signOut() async {
    if (_client?.auth.currentSession != null) {
      await _client!.auth.signOut();
    }
  }
}

class _RemoteSyncItem {
  const _RemoteSyncItem({
    required this.entityType,
    required this.entityId,
    required this.updatedAt,
    required this.deletedAt,
    required this.payload,
  });

  final SyncEntityType entityType;
  final String entityId;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final Map<String, dynamic>? payload;

  DateTime get lastModified => deletedAt ?? updatedAt;

  static _RemoteSyncItem? fromJson(Map<String, dynamic> json) {
    final typeName = json['entity_type'];
    final entityId = json['entity_id'];
    final updatedAt = DateTime.tryParse(json['updated_at'] as String? ?? '');
    if (typeName is! String || entityId is! String || updatedAt == null) {
      return null;
    }

    SyncEntityType? type;
    for (final candidate in SyncEntityType.values) {
      if (candidate.name == typeName) {
        type = candidate;
        break;
      }
    }
    if (type == null) {
      return null;
    }

    final rawPayload = json['payload'];
    return _RemoteSyncItem(
      entityType: type,
      entityId: entityId,
      updatedAt: updatedAt.toUtc(),
      deletedAt: DateTime.tryParse(json['deleted_at'] as String? ?? '')?.toUtc(),
      payload: rawPayload is Map
          ? Map<String, dynamic>.from(rawPayload)
          : null,
    );
  }
}
