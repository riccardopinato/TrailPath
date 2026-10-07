import 'package:trail_path/core/domain/cloud_sync.dart';

abstract interface class CloudSyncEngine {
  bool get isConfigured;

  Future<CloudSyncSnapshot> syncNow();

  Future<void> signOut();
}

abstract interface class AccountDeletingCloudSyncEngine
    implements CloudSyncEngine {
  /// Permanently removes the authenticated TrailPath cloud account and its
  /// server-side data. Implementations must fail closed if the backend cannot
  /// prove that deletion completed.
  Future<void> deleteAccount();
}
