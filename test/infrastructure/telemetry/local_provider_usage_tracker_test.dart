import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/database/app_database.dart';
import 'package:trail_path/infrastructure/telemetry/local_provider_usage_tracker.dart';

void main() {
  test('provider usage tracker stores only aggregate counters and timestamps',
      () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);
    final tracker = LocalProviderUsageTracker(database);

    await tracker.record(provider: 'MapTiler', capability: 'Satellite');
    await tracker.record(provider: 'MapTiler', capability: 'Satellite');

    expect(
      await database.getSetting('provider_usage_maptiler_satellite_count'),
      '2',
    );
    final stamp = await database.getSetting(
      'provider_usage_maptiler_satellite_last_at',
    );
    expect(stamp, isNotNull);
    expect(DateTime.tryParse(stamp!), isNotNull);

    expect(
      await database.getSetting('provider_usage_maptiler_satellite_latitude'),
      isNull,
    );
    expect(
      await database.getSetting('provider_usage_maptiler_satellite_longitude'),
      isNull,
    );
  });
}
