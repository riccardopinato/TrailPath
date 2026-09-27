import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trail_path/core/config/cloud_config.dart';
import 'package:trail_path/core/database/database_providers.dart';
import 'package:trail_path/core/domain/cloud_sync.dart';
import 'package:trail_path/core/services/cloud_sync_engine.dart';
import 'package:trail_path/features/outdoor/application/battery_mode_controller.dart';
import 'package:trail_path/features/profile/application/account_controller.dart';
import 'package:trail_path/features/settings/application/settings_controller.dart';
import 'package:trail_path/infrastructure/sync/supabase_cloud_sync_engine.dart';

final cloudSyncEngineProvider = Provider<CloudSyncEngine>((ref) {
  final client = CloudConfig.isRuntimeAvailable
      ? Supabase.instance.client
      : null;
  return SupabaseCloudSyncEngine(
    database: ref.watch(appDatabaseProvider),
    accountService: ref.watch(accountServiceProvider),
    client: client,
  );
});

final cloudSyncControllerProvider =
    NotifierProvider<CloudSyncController, CloudSyncSnapshot>(
      CloudSyncController.new,
    );

class CloudSyncController extends Notifier<CloudSyncSnapshot> {
  late CloudSyncEngine _engine;

  @override
  CloudSyncSnapshot build() {
    _engine = ref.watch(cloudSyncEngineProvider);
    unawaited(_loadInitialState());
    return CloudSyncSnapshot(isConfigured: _engine.isConfigured);
  }

  Future<void> _loadInitialState() async {
    final database = ref.read(appDatabaseProvider);
    final lastRaw = await database.getSetting('last_cloud_sync_at');
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(
      isConfigured: _engine.isConfigured,
      lastSyncedAt: lastRaw == null
          ? null
          : DateTime.tryParse(lastRaw)?.toLocal(),
      pendingChanges: await database.pendingSyncCount(),
    );
  }

  Future<void> syncNow() async {
    if (state.isBusy) {
      return;
    }
    state = state.copyWith(phase: CloudSyncPhase.syncing, clearError: true);
    final result = await _engine.syncNow();
    if (ref.mounted) {
      state = result.copyWith(lastSyncedAt: result.lastSyncedAt?.toLocal());
      ref.invalidate(savedRoutesProvider);
      ref.invalidate(completedActivitiesProvider);
      ref.invalidate(settingsControllerProvider);
      ref.invalidate(batteryModeProvider);
    }
  }

  Future<void> signOut() async {
    await _engine.signOut();
    if (ref.mounted) {
      state = state.copyWith(phase: CloudSyncPhase.idle, clearError: true);
    }
  }
}
