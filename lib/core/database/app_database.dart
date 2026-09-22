import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._(super.executor);

  factory AppDatabase.open() => AppDatabase._(_openConnection());

  factory AppDatabase.memory() => AppDatabase._(NativeDatabase.memory());

  @override
  int get schemaVersion => 3;

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
        },
      );

  Stream<List<SavedRoute>> watchSavedRoutes() {
    return (select(savedRoutes)
          ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]))
        .watch();
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
              if (point.elevationMeters != null)
                'ele': point.elevationMeters,
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
        batch.insertAll(
          waypoints,
          [
            for (var index = 0; index < waypointsData.length; index++)
              WaypointsCompanion.insert(
                id: '$id-wp-$index',
                routeId: id,
                sortIndex: index,
                latitude: waypointsData[index].latitude,
                longitude: waypointsData[index].longitude,
                elevationMeters:
                    Value(waypointsData[index].elevationMeters),
              ),
          ],
        );
      });
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

  Future<String> createActivityDraft({
    required RouteProfile profile,
  }) async {
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
    await (update(activities)..where((row) => row.id.equals(activityId))).write(
      ActivitiesCompanion(
        name: Value(name),
        endedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        distanceMeters: Value(snapshot.distanceMeters),
        ascentMeters: Value(snapshot.ascentMeters),
        movingSeconds: Value(snapshot.elapsed.inSeconds),
        encodedGeometry: Value(_encodePoints(snapshot.points)),
        isPaused: const Value(false),
      ),
    );
  }

  Future<void> discardActivity(String activityId) async {
    await (delete(activities)..where((row) => row.id.equals(activityId))).go();
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
      SavedRoutesCompanion(
        isOfflineReady: Value(isReady),
        updatedAt: Value(DateTime.now()),
      ),
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
    final row = await (select(savedReturnPoints)
          ..where((candidate) => candidate.id.equals('car'))
          ..limit(1))
        .getSingleOrNull();
    return _returnPointFromRow(row);
  }

  Future<void> clearReturnPoint() async {
    await (delete(savedReturnPoints)..where((row) => row.id.equals('car'))).go();
  }

  Future<void> setSetting(String key, String value) async {
    await into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(
        key: key,
        value: value,
      ),
    );
  }

  Future<String?> getSetting(String key) async {
    final row = await (select(appSettings)
          ..where((candidate) => candidate.key.equals(key))
          ..limit(1))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> deleteSavedRoute(String routeId) async {
    await transaction(() async {
      await (delete(waypoints)..where((row) => row.routeId.equals(routeId)))
          .go();
      await (delete(savedRoutes)..where((row) => row.id.equals(routeId))).go();
    });
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
