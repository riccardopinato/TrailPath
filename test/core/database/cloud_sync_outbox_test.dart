import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/database/app_database.dart';
import 'package:trail_path/core/domain/cloud_sync.dart';
import 'package:trail_path/core/domain/models.dart';

void main() {
  test('saved routes enter the offline-first sync outbox', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);

    final routeId = await database.savePlannedRoute(
      name: 'Sync route',
      profile: RouteProfile.hiking.name,
      waypointsData: const [
        GeoPoint(latitude: 45.0, longitude: 11.0),
        GeoPoint(latitude: 45.01, longitude: 11.01),
      ],
      geometryData: const [
        GeoPoint(latitude: 45.0, longitude: 11.0),
        GeoPoint(latitude: 45.01, longitude: 11.01),
      ],
      distanceMeters: 1500,
      ascentMeters: 120,
      descentMeters: 80,
      estimatedDuration: const Duration(minutes: 25),
    );

    final pending = await database.listSyncMutations();
    expect(pending, hasLength(1));
    expect(pending.single.entityType, SyncEntityType.route);
    expect(pending.single.entityId, routeId);
    expect(pending.single.action, SyncMutationAction.upsert);

    final payload = await database.routeSyncPayload(routeId);
    expect(payload, isNotNull);
    expect(payload!['name'], 'Sync route');
    expect(payload['waypoints'], isA<List<Object?>>());
  });

  test('route delete becomes a tombstone mutation', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);

    final routeId = await database.savePlannedRoute(
      name: 'Delete route',
      profile: RouteProfile.walking.name,
      waypointsData: const [
        GeoPoint(latitude: 45.0, longitude: 11.0),
        GeoPoint(latitude: 45.001, longitude: 11.001),
      ],
      geometryData: const [
        GeoPoint(latitude: 45.0, longitude: 11.0),
        GeoPoint(latitude: 45.001, longitude: 11.001),
      ],
      distanceMeters: 150,
      ascentMeters: 2,
      descentMeters: 1,
      estimatedDuration: const Duration(minutes: 3),
    );

    await database.deleteSavedRoute(routeId);

    final pending = await database.listSyncMutations();
    expect(pending, hasLength(1));
    expect(pending.single.entityId, routeId);
    expect(pending.single.action, SyncMutationAction.delete);
  });

  test('cloud preferences are coalesced into one mutation', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);

    await database.setSetting('preference_theme', 'dark');
    await database.setSetting('preference_voice_guidance', 'false');

    final pending = await database.listSyncMutations();
    final preferenceMutations = pending
        .where((item) => item.entityType == SyncEntityType.preferences)
        .toList();

    expect(preferenceMutations, hasLength(1));
    final payload = await database.preferencesSyncPayload();
    final values = payload['values'] as Map<String, String>;
    expect(values['preference_theme'], 'dark');
    expect(values['preference_voice_guidance'], 'false');
  });
}
