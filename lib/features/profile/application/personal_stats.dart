import 'package:trail_path/core/domain/route_intelligence.dart';

PersonalStats buildPersonalStats(List<Activity> activities, {DateTime? now}) {
  final reference = (now ?? DateTime.now()).toLocal();
  final start7 = reference.subtract(const Duration(days: 7));
  final start30 = reference.subtract(const Duration(days: 30));

  var distance = 0.0;
  var ascent = 0.0;
  var movingSeconds = 0;
  var last7 = 0.0;
  var last30 = 0.0;
  var longest = 0.0;
  var highestAscent = 0.0;

  for (final activity in activities) {
    distance += activity.distanceMeters;
    ascent += activity.ascentMeters;
    movingSeconds += activity.movingSeconds;
    longest = activity.distanceMeters > longest
        ? activity.distanceMeters
        : longest;
    highestAscent = activity.ascentMeters > highestAscent
        ? activity.ascentMeters
        : highestAscent;

    final ended = activity.endedAt?.toLocal() ?? activity.startedAt.toLocal();
    if (!ended.isBefore(start30)) {
      last30 += activity.distanceMeters;
    }
    if (!ended.isBefore(start7)) {
      last7 += activity.distanceMeters;
    }
  }

  return PersonalStats(
    activityCount: activities.length,
    totalDistanceMeters: distance,
    totalAscentMeters: ascent,
    totalMovingTime: Duration(seconds: movingSeconds),
    last7DaysDistanceMeters: last7,
    last30DaysDistanceMeters: last30,
    longestActivityMeters: longest,
    highestAscentMeters: highestAscent,
  );
}
