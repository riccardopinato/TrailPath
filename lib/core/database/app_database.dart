import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

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
  AppDatabase._(QueryExecutor executor) : super(executor);

  factory AppDatabase.open() => AppDatabase._(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/trailpath.sqlite');
    return NativeDatabase.createInBackground(file);
  });
}
