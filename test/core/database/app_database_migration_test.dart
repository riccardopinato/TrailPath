import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/database/app_database.dart';
import 'package:trail_path/core/domain/models.dart';

void main() {
  for (final legacyVersion in [1, 2]) {
    test('migrates schema v$legacyVersion to v3 without data loss', () async {
      final executor = _legacyDatabase(legacyVersion);
      final database = AppDatabase.forTesting(executor);
      addTearDown(database.close);

      // Opening the first query executes Drift's migration strategy.
      const versionPragma = 'PRAGMA user_version';
      final versionRow = await database.customSelect(versionPragma).getSingle();
      expect(versionRow.read<int>('user_version'), 3);

      final completed = await database.watchCompletedActivities().first;
      expect(completed, hasLength(1));
      expect(completed.single.id, 'legacy-activity');
      expect(completed.single.name, 'Legacy activity');
      expect(completed.single.distanceMeters, 42);
      expect(completed.single.ascentMeters, 3);

      final activityId = await database.createActivityDraft(
        profile: RouteProfile.hiking,
      );
      await database.updateActivityDraft(
        activityId: activityId,
        snapshot: const TrackRecorderSnapshot(
          status: TrackRecorderStatus.paused,
          points: [
            GeoPoint(latitude: 45.0, longitude: 11.0),
            GeoPoint(latitude: 45.001, longitude: 11.001),
          ],
          distanceMeters: 140,
          ascentMeters: 8,
          elapsed: Duration(minutes: 2),
        ),
      );

      final recoverable = await database.latestRecoverableActivity();
      expect(recoverable, isNotNull);
      expect(recoverable!.id, activityId);
      expect(recoverable.isPaused, isTrue);
      expect(recoverable.profile, RouteProfile.hiking.name);

      await database.saveReturnPoint(
        point: const GeoPoint(latitude: 45.2, longitude: 11.7),
        accuracyMeters: 5,
      );
      expect(await database.getReturnPoint(), isNotNull);

      await database.setSetting('migration_probe', 'ok');
      expect(await database.getSetting('migration_probe'), 'ok');
    });
  }
}

NativeDatabase _legacyDatabase(int version) {
  return NativeDatabase.memory(
    setup: (raw) {
      raw.execute('''
CREATE TABLE saved_routes (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  distance_meters REAL NOT NULL DEFAULT 0,
  ascent_meters REAL NOT NULL DEFAULT 0,
  descent_meters REAL NOT NULL DEFAULT 0,
  duration_seconds INTEGER NOT NULL DEFAULT 0,
  profile TEXT NOT NULL,
  encoded_geometry TEXT,
  is_offline_ready INTEGER NOT NULL DEFAULT 0 CHECK (is_offline_ready IN (0, 1))
);
''');

      raw.execute('''
CREATE TABLE activities (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT,
  route_id TEXT,
  started_at INTEGER NOT NULL,
  ended_at INTEGER,
  distance_meters REAL NOT NULL DEFAULT 0,
  ascent_meters REAL NOT NULL DEFAULT 0,
  moving_seconds INTEGER NOT NULL DEFAULT 0
  ${version >= 2 ? ",\n  updated_at INTEGER,\n  profile TEXT NOT NULL DEFAULT 'hiking',\n  encoded_geometry TEXT,\n  is_paused INTEGER NOT NULL DEFAULT 0 CHECK (is_paused IN (0, 1))" : ''}
);
''');

      raw.execute('''
CREATE TABLE waypoints (
  id TEXT NOT NULL PRIMARY KEY,
  route_id TEXT NOT NULL,
  sort_index INTEGER NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  elevation_meters REAL,
  name TEXT
);
''');

      raw.execute(
        "INSERT INTO activities "
        "(id, name, started_at, ended_at, distance_meters, ascent_meters, "
        "moving_seconds) "
        "VALUES ('legacy-activity', 'Legacy activity', 0, 60, 42, 3, 60);",
      );

      raw.execute('PRAGMA user_version = $version;');
    },
  );
}
