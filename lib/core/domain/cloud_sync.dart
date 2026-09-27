enum SyncEntityType { route, activity, preferences }

enum SyncMutationAction { upsert, delete }

enum CloudSyncPhase { idle, syncing, success, unavailable, error }

class SyncMutation {
  const SyncMutation({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.updatedAt,
  });

  final int id;
  final SyncEntityType entityType;
  final String entityId;
  final SyncMutationAction action;
  final DateTime updatedAt;
}

class CloudSyncSnapshot {
  const CloudSyncSnapshot({
    this.phase = CloudSyncPhase.idle,
    this.isConfigured = false,
    this.lastSyncedAt,
    this.pendingChanges = 0,
    this.error,
  });

  final CloudSyncPhase phase;
  final bool isConfigured;
  final DateTime? lastSyncedAt;
  final int pendingChanges;
  final String? error;

  bool get isBusy => phase == CloudSyncPhase.syncing;

  CloudSyncSnapshot copyWith({
    CloudSyncPhase? phase,
    bool? isConfigured,
    DateTime? lastSyncedAt,
    int? pendingChanges,
    String? error,
    bool clearError = false,
  }) {
    return CloudSyncSnapshot(
      phase: phase ?? this.phase,
      isConfigured: isConfigured ?? this.isConfigured,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      pendingChanges: pendingChanges ?? this.pendingChanges,
      error: clearError ? null : error ?? this.error,
    );
  }
}
