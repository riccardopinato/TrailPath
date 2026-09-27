import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/infrastructure/sync/supabase_cloud_sync_engine.dart';

void main() {
  test('cloud sync owner accepts first binding and same account', () {
    expect(cloudSyncOwnerMatches(null, 'user-a'), isTrue);
    expect(cloudSyncOwnerMatches('', 'user-a'), isTrue);
    expect(cloudSyncOwnerMatches('user-a', 'user-a'), isTrue);
  });

  test(
    'cloud sync owner blocks a different account on the same local data',
    () {
      expect(cloudSyncOwnerMatches('user-a', 'user-b'), isFalse);
    },
  );
}
