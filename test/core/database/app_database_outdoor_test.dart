import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/database/app_database.dart';
import 'package:trail_path/core/domain/models.dart';

void main() {
  test('persists and clears back-to-car return point', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);

    await database.saveReturnPoint(
      point: const GeoPoint(
        latitude: 45.123,
        longitude: 11.456,
        elevationMeters: 120,
      ),
      accuracyMeters: 6.5,
    );

    final saved = await database.getReturnPoint();
    expect(saved, isNotNull);
    expect(saved!.id, 'car');
    expect(saved.point.latitude, 45.123);
    expect(saved.point.longitude, 11.456);
    expect(saved.point.elevationMeters, 120);
    expect(saved.accuracyMeters, 6.5);

    await database.clearReturnPoint();
    expect(await database.getReturnPoint(), isNull);
  });

  test('persists generic app settings', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);

    await database.setSetting('battery_mode', 'saver');
    expect(await database.getSetting('battery_mode'), 'saver');

    await database.setSetting('battery_mode', 'performance');
    expect(await database.getSetting('battery_mode'), 'performance');
  });
}
