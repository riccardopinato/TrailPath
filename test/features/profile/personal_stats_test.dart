import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/database/app_database.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/features/profile/application/personal_stats.dart';

void main() {
  test('personal stats aggregate totals and rolling windows', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);

    final id1 = await database.createActivityDraft(
      profile: RouteProfile.hiking,
    );
    await database.completeActivity(
      activityId: id1,
      name: 'Recent activity',
      snapshot: const TrackRecorderSnapshot(
        status: TrackRecorderStatus.completed,
        points: [
          GeoPoint(latitude: 45.0, longitude: 11.0),
          GeoPoint(latitude: 45.01, longitude: 11.01),
        ],
        distanceMeters: 5000,
        elapsed: Duration(hours: 1),
        ascentMeters: 350,
      ),
    );

    final id2 = await database.createActivityDraft(
      profile: RouteProfile.walking,
    );
    await database.completeActivity(
      activityId: id2,
      name: 'Second activity',
      snapshot: const TrackRecorderSnapshot(
        status: TrackRecorderStatus.completed,
        points: [
          GeoPoint(latitude: 45.1, longitude: 11.1),
          GeoPoint(latitude: 45.12, longitude: 11.12),
        ],
        distanceMeters: 8000,
        elapsed: Duration(hours: 2),
        ascentMeters: 500,
      ),
    );

    final activities = await database.watchCompletedActivities().first;
    final now = DateTime.now().add(const Duration(minutes: 1));
    final stats = buildPersonalStats(activities, now: now);

    expect(stats.activityCount, 2);
    expect(stats.totalDistanceMeters, 13000);
    expect(stats.totalAscentMeters, 850);
    expect(stats.totalMovingTime, const Duration(hours: 3));
    expect(stats.last7DaysDistanceMeters, 13000);
    expect(stats.last30DaysDistanceMeters, 13000);
    expect(stats.longestActivityMeters, 8000);
    expect(stats.highestAscentMeters, 500);
  });
}
