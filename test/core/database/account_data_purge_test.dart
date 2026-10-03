import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/database/app_database.dart';
import 'package:trail_path/core/domain/models.dart';

void main() {
  test('account deletion purge removes local user-owned database state', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);

    await database.setSetting('cloud_sync_owner_user_id', 'user-a');
    await database.savePlannedRoute(
      name: 'Private route',
      profile: RouteProfile.hiking.name,
      waypointsData: const [
        GeoPoint(latitude: 45.20, longitude: 11.70),
        GeoPoint(latitude: 45.21, longitude: 11.71),
      ],
      geometryData: const [
        GeoPoint(latitude: 45.20, longitude: 11.70),
        GeoPoint(latitude: 45.21, longitude: 11.71),
      ],
      distanceMeters: 1500,
      ascentMeters: 80,
      descentMeters: 40,
      estimatedDuration: const Duration(minutes: 25),
    );

    expect(await database.listSavedRoutes(), isNotEmpty);
    expect(await database.getSetting('cloud_sync_owner_user_id'), 'user-a');
    expect(await database.pendingSyncCount(), greaterThan(0));

    await database.deleteAllUserData();

    expect(await database.listSavedRoutes(), isEmpty);
    expect(await database.listCompletedActivities(), isEmpty);
    expect(await database.listRouteCollections(), isEmpty);
    expect(await database.getSetting('cloud_sync_owner_user_id'), isNull);
    expect(await database.pendingSyncCount(), 0);
  });
}
