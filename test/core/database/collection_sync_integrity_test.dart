import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/database/app_database.dart';
import 'package:trail_path/core/domain/cloud_sync.dart';
import 'package:trail_path/core/domain/models.dart';

void main() {
  test('deleting a collected route queues route tombstone and collection update', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);

    final routeId = await database.savePlannedRoute(
      name: 'Collected route',
      profile: RouteProfile.hiking.name,
      waypointsData: const [
        GeoPoint(latitude: 45.0, longitude: 11.0),
        GeoPoint(latitude: 45.01, longitude: 11.01),
      ],
      geometryData: const [
        GeoPoint(latitude: 45.0, longitude: 11.0),
        GeoPoint(latitude: 45.01, longitude: 11.01),
      ],
      distanceMeters: 1400,
      ascentMeters: 100,
      descentMeters: 90,
      estimatedDuration: const Duration(minutes: 25),
    );
    final collectionId = await database.createRouteCollection('Weekend');
    await database.addRouteToCollection(collectionId, routeId);

    for (final mutation in await database.listSyncMutations()) {
      await database.acknowledgeSyncMutation(mutation.id);
    }

    await database.deleteSavedRoute(routeId);

    final mutations = await database.listSyncMutations();
    expect(
      mutations.any(
        (item) =>
            item.entityType == SyncEntityType.route &&
            item.entityId == routeId &&
            item.action == SyncMutationAction.delete,
      ),
      isTrue,
    );
    expect(
      mutations.any(
        (item) =>
            item.entityType == SyncEntityType.collection &&
            item.entityId == collectionId &&
            item.action == SyncMutationAction.upsert,
      ),
      isTrue,
    );
    expect(await database.listCollectionRouteIds(collectionId), isEmpty);
  });
}
