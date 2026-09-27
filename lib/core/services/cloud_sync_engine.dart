import 'package:trail_path/core/domain/cloud_sync.dart';

abstract interface class CloudSyncEngine {
  bool get isConfigured;

  Future<CloudSyncSnapshot> syncNow();

  Future<void> signOut();
}
