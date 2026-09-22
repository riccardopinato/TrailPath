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

  RealColumn get distanceMeters => real().withDefault(const Constant(0))();

  RealColumn get ascentMeters => real().withDefault(const Constant(0))();

  IntColumn get movingSeconds => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
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

@DriftDatabase(tables: [SavedRoutes, Activities, Waypoints])
class AppDatabase extends _$AppDatabase {
  AppDatabase._(super.executor);

  factory AppDatabase.open() => AppDatabase._(_openConnection());

  factory AppDatabase.memory() => AppDatabase._(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

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

  Future<void> deleteSavedRoute(String routeId) async {
    await transaction(() async {
      await (delete(waypoints)..where((row) => row.routeId.equals(routeId)))
          .go();
      await (delete(savedRoutes)..where((row) => row.id.equals(routeId))).go();
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/trailpath.sqlite');
    return NativeDatabase.createInBackground(file);
  });
}
