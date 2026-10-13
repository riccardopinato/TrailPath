import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v1.4 cloud sync is optional, offline-first and RLS-scoped', () {
    final database = File('lib/core/database/app_database.dart')
        .readAsStringSync();
    final engine = File(
      'lib/infrastructure/sync/supabase_cloud_sync_engine.dart',
    ).readAsStringSync();
    final schema = File('docs/SUPABASE_CLOUD_SYNC_SCHEMA.sql')
        .readAsStringSync();
    final main = File('lib/main.dart').readAsStringSync();

    expect(database, contains('SyncOutboxEntries'));
    expect(database, contains('SyncMutationAction.delete'));
    expect(database, contains('ensureInitialSyncOutbox'));
    expect(engine, contains("onConflict: 'user_id,entity_type,entity_id'"));
    expect(engine, contains('signInWithIdToken'));
    expect(engine, contains('accessToken == null'));
    expect(engine, contains('cloud_sync_owner_user_id'));
    expect(engine, contains('cloudSyncOwnerMatches'));
    expect(schema, contains('enable row level security'));
    expect(schema, contains('(select auth.uid()) = user_id'));
    expect(schema, isNot(contains('service_role')));
    expect(main, contains('if (CloudConfig.isConfigured)'));
    expect(main, contains('continuing local-first'));
    final controller = File(
      'lib/features/profile/application/cloud_sync_controller.dart',
    ).readAsStringSync();
    expect(controller, contains('CloudConfig.isRuntimeAvailable'));
  });
}
