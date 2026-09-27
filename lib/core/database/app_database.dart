import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:trail_path/core/domain/cloud_sync.dart';
import 'package:trail_path/core/domain/models.dart';

part 'app_database.g.dart';

class SavedRoutes extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().withLength(min: 1, max: 160)();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  RealColumn get distanceMeters => real().withDefault(const Constant(0))();

  RealColumn get ascentMeters => real().withDefault(const Constant(0))();

  RealColumn get descentMeters => real().withDefault(const Constant(0))();

  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();

  TextColumn get profile => text()();

  TextColumn get encodedGeometry => text().nullable()();

  BoolColumn get isOfflineReady =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Activities extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().nullable()();

  TextColumn get routeId => text().nullable()();

  DateTimeColumn get startedAt => dateTime()();

  DateTimeColumn get endedAt => dateTime().nullable()();

  DateTimeColumn get updatedAt => dateTime().nullable()();

  RealColumn get distanceMeters => real().withDefault(const Constant(0))();

  RealColumn get ascentMeters => real().withDefault(const Constant(0))();

  IntColumn get movingSeconds => integer().withDefault(const Constant(0))();

  TextColumn get profile => text().withDefault(const Constant('hiking'))();

  TextColumn get encodedGeometry => text().nullable()();

  BoolColumn get isPaused => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SavedReturnPoints extends Table {
  TextColumn get id => text()();

  RealColumn get latitude => real()();

  RealColumn get longitude => real()();

  RealColumn get elevationMeters => real().nullable()();

  DateTimeColumn get savedAt => dateTime()();

  RealColumn get accuracyMeters => real()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AppSettings extends Table {
  TextColumn get key => text()();

  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class SyncOutboxEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get entityType => text()();

  TextColumn get entityId => text()();

  TextColumn get action => text()();

  DateTimeColumn get updatedAt => dateTime()();
}

class Waypoints extends Table {
  TextColumn get id => text()();

  TextColumn get routeId => text()();

  IntColumn get sortIndex => integer()();

  RealColumn get latitude => real()();

  RealColumn get longitude => real()();

  RealColumn get elevationMeters => real().nullable()();

  TextColumn get name => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    SavedRoutes,
    Activities,
    Waypoints,
    SavedReturnPoints,
    AppSettings,
    SyncOutboxEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._(super.executor);

  factory AppDatabase.open() => AppDatabase._(_openConnection());

  factory AppDatabase.memory() => AppDatabase._(NativeDatabase.memory());

  factory AppDatabase.forTesting(QueryExecutor executor) =>
      AppDatabase._(executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(activities, activities.updatedAt);
        await migrator.addColumn(activities, activities.profile);
        await migrator.addColumn(activities, activities.encodedGeometry);
        await migrator.addColumn(activities, activities.isPaused);
      }
      if (from < 3) {
        await migrator.createTable(savedReturnPoints);
        await migrator.createTable(appSettings);
      }
      if (from < 4) {
        await migrator.createTable(syncOutboxEntries);
      }
    },
  );

  Stream<List<SavedRoute>> watchSavedRoutes() {
    return (select(
      savedRoutes,
    )..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])).watch();
  }

  Future<List<SavedRoute>> listSavedRoutes() {
    return (select(
      savedRoutes,
    )..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])).get();
  }

  Future<String> savePlannedRoute({
    required String name,
    required String profile,
    required List<GeoPoint> waypointsData,
    required List<GeoPoint> geometryData,
    required double distanceMeters,
    required double ascentMeters,
    required double descentMeters,
    required Duration estimatedDuration,
  }) async {
    if (waypointsData.length < 2 || geometryData.length < 2) {
      throw ArgumentError('A route requires at least two points.');
    }

    final now = DateTime.now();
    final id = 'route-${now.microsecondsSinceEpoch}';
    final geometry = jsonEncode(
      geometryData
          .map(
            (point) => {
              'lat': point.latitude,
              'lon': point.longitude,
              if (point.elevationMeters != null) 'ele': point.elevationMeters,
              if (point.timestamp != null)
                'time': point.timestamp!.toUtc().toIso8601String(),
            },
          )
          .toList(growable: false),
    );

    await transaction(() async {
      await into(savedRoutes).insert(
        SavedRoutesCompanion.insert(
          id: id,
          name: name,
          createdAt: now,
          updatedAt: now,
          profile: profile,
          distanceMeters: Value(distanceMeters),
          ascentMeters: Value(ascentMeters),
          descentMeters: Value(descentMeters),
          durationSeconds: Value(estimatedDuration.inSeconds),
          encodedGeometry: Value(geometry),
        ),
      );

      await batch((batch) {
        batch.insertAll(waypoints, [
          for (var index = 0; index < waypointsData.length; index++)
            WaypointsCompanion.insert(
              id: '$id-wp-$index',
              routeId: id,
              sortIndex: index,
              latitude: waypointsData[index].latitude,
              longitude: waypointsData[index].longitude,
              elevationMeters: Value(waypointsData[index].elevationMeters),
            ),
        ]);
      });
      await _queueSyncMutation(
        SyncEntityType.route,
        id,
        SyncMutationAction.upsert,
        updatedAt: now,
      );
    });

    return id;
  }

  GpxDocument savedRouteToGpx(SavedRoute route) {
    final encoded = route.encodedGeometry;
    if (encoded == null || encoded.isEmpty) {
      throw const FormatException('Saved route has no geometry.');
    }

    final decoded = jsonDecode(encoded);
    if (decoded is! List) {
      throw const FormatException('Saved route geometry is invalid.');
    }

    final points = <GeoPoint>[];
    for (final entry in decoded) {
      if (entry is! Map) {
        continue;
      }
      final latitude = entry['lat'];
      final longitude = entry['lon'];
      if (latitude is! num || longitude is! num) {
        continue;
      }
      final elevation = entry['ele'];
      final time = entry['time'];

      points.add(
        GeoPoint(
          latitude: latitude.toDouble(),
          longitude: longitude.toDouble(),
          elevationMeters: elevation is num ? elevation.toDouble() : null,
          timestamp: time is String ? DateTime.tryParse(time) : null,
        ),
      );
    }

    if (points.length < 2) {
      throw const FormatException('Saved route geometry is incomplete.');
    }

    return GpxDocument(
      name: route.name,
      points: List<GeoPoint>.unmodifiable(points),
    );
  }

  RoutePlan savedRouteToPlan(SavedRoute route) {
    final document = savedRouteToGpx(route);
    return RoutePlan(
      geometry: document.points,
      distanceMeters: route.distanceMeters,
      ascentMeters: route.ascentMeters,
      descentMeters: route.descentMeters,
      estimatedDuration: Duration(seconds: route.durationSeconds),
      profile: _routeProfileFromName(route.profile),
      isSnapped: true,
      routingSource: 'saved-route',
    );
  }

  Future<String> createActivityDraft({required RouteProfile profile}) async {
    final now = DateTime.now();
    final id = 'activity-${now.microsecondsSinceEpoch}';
    await into(activities).insert(
      ActivitiesCompanion.insert(
        id: id,
        startedAt: now,
        updatedAt: Value(now),
        profile: Value(profile.name),
        isPaused: const Value(false),
      ),
    );
    return id;
  }

  Future<void> updateActivityDraft({
    required String activityId,
    required TrackRecorderSnapshot snapshot,
  }) async {
    await (update(activities)..where((row) => row.id.equals(activityId))).write(
      ActivitiesCompanion(
        updatedAt: Value(DateTime.now()),
        distanceMeters: Value(snapshot.distanceMeters),
        ascentMeters: Value(snapshot.ascentMeters),
        movingSeconds: Value(snapshot.elapsed.inSeconds),
        encodedGeometry: Value(_encodePoints(snapshot.points)),
        isPaused: Value(snapshot.status == TrackRecorderStatus.paused),
      ),
    );
  }

  Future<void> completeActivity({
    required String activityId,
    required String name,
    required TrackRecorderSnapshot snapshot,
  }) async {
    final now = DateTime.now();
    await transaction(() async {
      await (update(
        activities,
      )..where((row) => row.id.equals(activityId))).write(
        ActivitiesCompanion(
          name: Value(name),
          endedAt: Value(now),
          updatedAt: Value(now),
          distanceMeters: Value(snapshot.distanceMeters),
          ascentMeters: Value(snapshot.ascentMeters),
          movingSeconds: Value(snapshot.elapsed.inSeconds),
          encodedGeometry: Value(_encodePoints(snapshot.points)),
          isPaused: const Value(false),
        ),
      );
      await _queueSyncMutation(
        SyncEntityType.activity,
        activityId,
        SyncMutationAction.upsert,
        updatedAt: now,
      );
    });
  }

  Future<void> discardActivity(String activityId) async {
    final existing =
        await (select(activities)
              ..where((row) => row.id.equals(activityId))
              ..limit(1))
            .getSingleOrNull();
    final now = DateTime.now();
    await transaction(() async {
      await (delete(
        activities,
      )..where((row) => row.id.equals(activityId))).go();
      if (existing?.endedAt != null) {
        await _queueSyncMutation(
          SyncEntityType.activity,
          activityId,
          SyncMutationAction.delete,
          updatedAt: now,
        );
      }
    });
  }

  Future<Activity?> latestRecoverableActivity() {
    return (select(activities)
          ..where((row) => row.endedAt.isNull())
          ..orderBy([(row) => OrderingTerm.desc(row.startedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Stream<List<Activity>> watchCompletedActivities() {
    return (select(activities)
          ..where((row) => row.endedAt.isNotNull())
          ..orderBy([(row) => OrderingTerm.desc(row.startedAt)]))
        .watch();
  }

  List<GeoPoint> decodeActivityPoints(Activity activity) {
    return _decodePoints(activity.encodedGeometry);
  }

  GpxDocument activityToGpx(Activity activity) {
    final points = decodeActivityPoints(activity);
    if (points.length < 2) {
      throw const FormatException('Activity geometry is incomplete.');
    }
    return GpxDocument(
      name: activity.name ?? 'TrailPath activity',
      points: points,
    );
  }

  Future<void> setSavedRouteOfflineReady(
    String routeId, {
    required bool isReady,
  }) async {
    await (update(savedRoutes)..where((row) => row.id.equals(routeId))).write(
      SavedRoutesCompanion(isOfflineReady: Value(isReady)),
    );
  }

  Future<void> saveReturnPoint({
    required GeoPoint point,
    required double accuracyMeters,
  }) async {
    await into(savedReturnPoints).insertOnConflictUpdate(
      SavedReturnPointsCompanion.insert(
        id: 'car',
        latitude: point.latitude,
        longitude: point.longitude,
        elevationMeters: Value(point.elevationMeters),
        savedAt: DateTime.now(),
        accuracyMeters: accuracyMeters,
      ),
    );
  }

  Stream<ReturnPoint?> watchReturnPoint() {
    return (select(savedReturnPoints)
          ..where((row) => row.id.equals('car'))
          ..limit(1))
        .watchSingleOrNull()
        .map(_returnPointFromRow);
  }

  Future<ReturnPoint?> getReturnPoint() async {
    final row =
        await (select(savedReturnPoints)
              ..where((candidate) => candidate.id.equals('car'))
              ..limit(1))
            .getSingleOrNull();
    return _returnPointFromRow(row);
  }

  Future<void> clearReturnPoint() async {
    await (delete(
      savedReturnPoints,
    )..where((row) => row.id.equals('car'))).go();
  }

  Future<void> setSetting(String key, String value) async {
    final now = DateTime.now();
    await transaction(() async {
      await into(appSettings).insertOnConflictUpdate(
        AppSettingsCompanion.insert(key: key, value: value),
      );
      if (_isCloudPreferenceKey(key)) {
        await into(appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: 'cloud_preferences_updated_at',
            value: now.toUtc().toIso8601String(),
          ),
        );
        await _queueSyncMutation(
          SyncEntityType.preferences,
          'preferences',
          SyncMutationAction.upsert,
          updatedAt: now,
        );
      }
    });
  }

  Future<String?> getSetting(String key) async {
    final row =
        await (select(appSettings)
              ..where((candidate) => candidate.key.equals(key))
              ..limit(1))
            .getSingleOrNull();
    return row?.value;
  }

  Future<void> deleteSavedRoute(String routeId) async {
    final now = DateTime.now();
    await transaction(() async {
      await (delete(
        waypoints,
      )..where((row) => row.routeId.equals(routeId))).go();
      await (delete(savedRoutes)..where((row) => row.id.equals(routeId))).go();
      await _queueSyncMutation(
        SyncEntityType.route,
        routeId,
        SyncMutationAction.delete,
        updatedAt: now,
      );
    });
  }

  Future<List<Activity>> listCompletedActivities() {
    return (select(activities)
          ..where((row) => row.endedAt.isNotNull())
          ..orderBy([(row) => OrderingTerm.desc(row.startedAt)]))
        .get();
  }

  Future<SavedRoute?> getSavedRoute(String routeId) {
    return (select(savedRoutes)
          ..where((row) => row.id.equals(routeId))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<Waypoint>> listRouteWaypoints(String routeId) {
    return (select(waypoints)
          ..where((row) => row.routeId.equals(routeId))
          ..orderBy([(row) => OrderingTerm.asc(row.sortIndex)]))
        .get();
  }

  Future<Activity?> getActivity(String activityId) {
    return (select(activities)
          ..where((row) => row.id.equals(activityId))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<Map<String, String>> listCloudPreferences() async {
    final rows = await select(appSettings).get();
    return <String, String>{
      for (final row in rows)
        if (_isCloudPreferenceKey(row.key)) row.key: row.value,
    };
  }

  Future<DateTime?> cloudPreferencesUpdatedAt() async {
    final value = await getSetting('cloud_preferences_updated_at');
    return value == null ? null : DateTime.tryParse(value)?.toUtc();
  }

  Future<void> ensureInitialSyncOutbox() async {
    final bootstrapped = await getSetting('cloud_sync_bootstrapped');
    if (bootstrapped == 'true') {
      return;
    }

    final routes = await listSavedRoutes();
    final completed = await listCompletedActivities();
    final preferences = await listCloudPreferences();
    await transaction(() async {
      for (final route in routes) {
        await _queueSyncMutation(
          SyncEntityType.route,
          route.id,
          SyncMutationAction.upsert,
          updatedAt: route.updatedAt,
        );
      }
      for (final activity in completed) {
        await _queueSyncMutation(
          SyncEntityType.activity,
          activity.id,
          SyncMutationAction.upsert,
          updatedAt:
              activity.updatedAt ?? activity.endedAt ?? activity.startedAt,
        );
      }
      if (preferences.isNotEmpty) {
        final updatedAt = await cloudPreferencesUpdatedAt() ?? DateTime.now();
        await _queueSyncMutation(
          SyncEntityType.preferences,
          'preferences',
          SyncMutationAction.upsert,
          updatedAt: updatedAt,
        );
      }
      await into(appSettings).insertOnConflictUpdate(
        AppSettingsCompanion.insert(
          key: 'cloud_sync_bootstrapped',
          value: 'true',
        ),
      );
    });
  }

  Future<List<SyncMutation>> listSyncMutations() async {
    final rows = await (select(
      syncOutboxEntries,
    )..orderBy([(row) => OrderingTerm.asc(row.updatedAt)])).get();
    return rows
        .map(
          (row) => SyncMutation(
            id: row.id,
            entityType: SyncEntityType.values.firstWhere(
              (value) => value.name == row.entityType,
            ),
            entityId: row.entityId,
            action: SyncMutationAction.values.firstWhere(
              (value) => value.name == row.action,
            ),
            updatedAt: row.updatedAt.toUtc(),
          ),
        )
        .toList(growable: false);
  }

  Future<int> pendingSyncCount() async {
    final rows = await select(syncOutboxEntries).get();
    return rows.length;
  }

  Future<void> acknowledgeSyncMutation(int mutationId) {
    return (delete(
      syncOutboxEntries,
    )..where((row) => row.id.equals(mutationId))).go();
  }

  Future<Map<String, Object?>?> routeSyncPayload(String routeId) async {
    final route = await getSavedRoute(routeId);
    if (route == null) {
      return null;
    }
    final routeWaypoints = await listRouteWaypoints(routeId);
    return <String, Object?>{
      'id': route.id,
      'name': route.name,
      'created_at': route.createdAt.toUtc().toIso8601String(),
      'updated_at': route.updatedAt.toUtc().toIso8601String(),
      'distance_meters': route.distanceMeters,
      'ascent_meters': route.ascentMeters,
      'descent_meters': route.descentMeters,
      'duration_seconds': route.durationSeconds,
      'profile': route.profile,
      'encoded_geometry': route.encodedGeometry,
      'waypoints': [
        for (final point in routeWaypoints)
          <String, Object?>{
            'id': point.id,
            'sort_index': point.sortIndex,
            'latitude': point.latitude,
            'longitude': point.longitude,
            'elevation_meters': point.elevationMeters,
            'name': point.name,
          },
      ],
    };
  }

  Future<Map<String, Object?>?> activitySyncPayload(String activityId) async {
    final activity = await getActivity(activityId);
    if (activity == null || activity.endedAt == null) {
      return null;
    }
    return <String, Object?>{
      'id': activity.id,
      'name': activity.name,
      'route_id': activity.routeId,
      'started_at': activity.startedAt.toUtc().toIso8601String(),
      'ended_at': activity.endedAt?.toUtc().toIso8601String(),
      'updated_at':
          (activity.updatedAt ?? activity.endedAt ?? activity.startedAt)
              .toUtc()
              .toIso8601String(),
      'distance_meters': activity.distanceMeters,
      'ascent_meters': activity.ascentMeters,
      'moving_seconds': activity.movingSeconds,
      'profile': activity.profile,
      'encoded_geometry': activity.encodedGeometry,
    };
  }

  Future<Map<String, Object?>> preferencesSyncPayload() async {
    final values = await listCloudPreferences();
    return <String, Object?>{'values': values};
  }

  Future<void> applyRemoteRoute(Map<String, dynamic> payload) async {
    final id = payload['id'] as String?;
    final name = payload['name'] as String?;
    final createdAt = DateTime.tryParse(payload['created_at'] as String? ?? '');
    final updatedAt = DateTime.tryParse(payload['updated_at'] as String? ?? '');
    final profile = payload['profile'] as String?;
    final rawWaypoints = payload['waypoints'];
    if (id == null ||
        name == null ||
        createdAt == null ||
        updatedAt == null ||
        profile == null ||
        rawWaypoints is! List) {
      throw const FormatException('Remote route payload is incomplete.');
    }

    await transaction(() async {
      await into(savedRoutes).insertOnConflictUpdate(
        SavedRoutesCompanion.insert(
          id: id,
          name: name,
          createdAt: createdAt.toLocal(),
          updatedAt: updatedAt.toLocal(),
          profile: profile,
          distanceMeters: Value(
            (payload['distance_meters'] as num?)?.toDouble() ?? 0,
          ),
          ascentMeters: Value(
            (payload['ascent_meters'] as num?)?.toDouble() ?? 0,
          ),
          descentMeters: Value(
            (payload['descent_meters'] as num?)?.toDouble() ?? 0,
          ),
          durationSeconds: Value(
            (payload['duration_seconds'] as num?)?.toInt() ?? 0,
          ),
          encodedGeometry: Value(payload['encoded_geometry'] as String?),
          isOfflineReady: const Value(false),
        ),
      );
      await (delete(waypoints)..where((row) => row.routeId.equals(id))).go();
      final rows = <WaypointsCompanion>[];
      for (final raw in rawWaypoints) {
        if (raw is! Map) {
          continue;
        }
        final item = Map<String, dynamic>.from(raw);
        final latitude = item['latitude'];
        final longitude = item['longitude'];
        final sortIndex = item['sort_index'];
        if (latitude is! num || longitude is! num || sortIndex is! num) {
          continue;
        }
        rows.add(
          WaypointsCompanion.insert(
            id: item['id'] as String? ?? '$id-wp-${sortIndex.toInt()}',
            routeId: id,
            sortIndex: sortIndex.toInt(),
            latitude: latitude.toDouble(),
            longitude: longitude.toDouble(),
            elevationMeters: Value(
              (item['elevation_meters'] as num?)?.toDouble(),
            ),
            name: Value(item['name'] as String?),
          ),
        );
      }
      if (rows.isNotEmpty) {
        await batch((batch) => batch.insertAll(waypoints, rows));
      }
    });
  }

  Future<void> applyRemoteActivity(Map<String, dynamic> payload) async {
    final id = payload['id'] as String?;
    final startedAt = DateTime.tryParse(payload['started_at'] as String? ?? '');
    final endedAt = DateTime.tryParse(payload['ended_at'] as String? ?? '');
    final updatedAt = DateTime.tryParse(payload['updated_at'] as String? ?? '');
    if (id == null ||
        startedAt == null ||
        endedAt == null ||
        updatedAt == null) {
      throw const FormatException('Remote activity payload is incomplete.');
    }
    await into(activities).insertOnConflictUpdate(
      ActivitiesCompanion.insert(
        id: id,
        startedAt: startedAt.toLocal(),
        name: Value(payload['name'] as String?),
        routeId: Value(payload['route_id'] as String?),
        endedAt: Value(endedAt.toLocal()),
        updatedAt: Value(updatedAt.toLocal()),
        distanceMeters: Value(
          (payload['distance_meters'] as num?)?.toDouble() ?? 0,
        ),
        ascentMeters: Value(
          (payload['ascent_meters'] as num?)?.toDouble() ?? 0,
        ),
        movingSeconds: Value((payload['moving_seconds'] as num?)?.toInt() ?? 0),
        profile: Value(payload['profile'] as String? ?? 'hiking'),
        encodedGeometry: Value(payload['encoded_geometry'] as String?),
        isPaused: const Value(false),
      ),
    );
  }

  Future<void> applyRemotePreferences(
    Map<String, dynamic> payload,
    DateTime updatedAt,
  ) async {
    final raw = payload['values'];
    if (raw is! Map) {
      return;
    }
    await transaction(() async {
      for (final entry in raw.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (_isCloudPreferenceKey(key) && value is String) {
          await into(appSettings).insertOnConflictUpdate(
            AppSettingsCompanion.insert(key: key, value: value),
          );
        }
      }
      await into(appSettings).insertOnConflictUpdate(
        AppSettingsCompanion.insert(
          key: 'cloud_preferences_updated_at',
          value: updatedAt.toUtc().toIso8601String(),
        ),
      );
    });
  }

  Future<void> applyRemoteDelete(
    SyncEntityType entityType,
    String entityId,
  ) async {
    switch (entityType) {
      case SyncEntityType.route:
        await transaction(() async {
          await (delete(
            waypoints,
          )..where((row) => row.routeId.equals(entityId))).go();
          await (delete(
            savedRoutes,
          )..where((row) => row.id.equals(entityId))).go();
        });
        break;
      case SyncEntityType.activity:
        await (delete(
          activities,
        )..where((row) => row.id.equals(entityId))).go();
        break;
      case SyncEntityType.preferences:
        break;
    }
  }

  Future<DateTime?> localSyncTimestamp(
    SyncEntityType entityType,
    String entityId,
  ) async {
    switch (entityType) {
      case SyncEntityType.route:
        return (await getSavedRoute(entityId))?.updatedAt.toUtc();
      case SyncEntityType.activity:
        final activity = await getActivity(entityId);
        return (activity?.updatedAt ?? activity?.endedAt ?? activity?.startedAt)
            ?.toUtc();
      case SyncEntityType.preferences:
        return cloudPreferencesUpdatedAt();
    }
  }

  Future<void> _queueSyncMutation(
    SyncEntityType entityType,
    String entityId,
    SyncMutationAction action, {
    required DateTime updatedAt,
  }) async {
    await (delete(syncOutboxEntries)
          ..where((row) => row.entityType.equals(entityType.name))
          ..where((row) => row.entityId.equals(entityId)))
        .go();
    await into(syncOutboxEntries).insert(
      SyncOutboxEntriesCompanion.insert(
        entityType: entityType.name,
        entityId: entityId,
        action: action.name,
        updatedAt: updatedAt,
      ),
    );
  }
}

ReturnPoint? _returnPointFromRow(SavedReturnPoint? row) {
  if (row == null) {
    return null;
  }
  return ReturnPoint(
    id: row.id,
    point: GeoPoint(
      latitude: row.latitude,
      longitude: row.longitude,
      elevationMeters: row.elevationMeters,
    ),
    savedAt: row.savedAt,
    accuracyMeters: row.accuracyMeters,
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/trailpath.sqlite');
    return NativeDatabase.createInBackground(file);
  });
}

String _encodePoints(List<GeoPoint> points) {
  return jsonEncode(
    points
        .map(
          (point) => {
            'lat': point.latitude,
            'lon': point.longitude,
            if (point.elevationMeters != null) 'ele': point.elevationMeters,
            if (point.timestamp != null)
              'time': point.timestamp!.toUtc().toIso8601String(),
          },
        )
        .toList(growable: false),
  );
}

List<GeoPoint> _decodePoints(String? encodedGeometry) {
  if (encodedGeometry == null || encodedGeometry.isEmpty) {
    return const [];
  }
  final decoded = jsonDecode(encodedGeometry);
  if (decoded is! List) {
    return const [];
  }

  final points = <GeoPoint>[];
  for (final entry in decoded) {
    if (entry is! Map) {
      continue;
    }
    final latitude = entry['lat'];
    final longitude = entry['lon'];
    if (latitude is! num || longitude is! num) {
      continue;
    }
    final elevation = entry['ele'];
    final time = entry['time'];
    points.add(
      GeoPoint(
        latitude: latitude.toDouble(),
        longitude: longitude.toDouble(),
        elevationMeters: elevation is num ? elevation.toDouble() : null,
        timestamp: time is String ? DateTime.tryParse(time) : null,
      ),
    );
  }
  return List<GeoPoint>.unmodifiable(points);
}

RouteProfile _routeProfileFromName(String value) {
  for (final profile in RouteProfile.values) {
    if (profile.name == value) {
      return profile;
    }
  }
  return RouteProfile.hiking;
}

bool _isCloudPreferenceKey(String key) {
  return key == 'battery_mode' || key.startsWith('preference_');
}
