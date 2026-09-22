import 'package:trail_path/core/domain/geo_math.dart';
import 'package:trail_path/core/domain/models.dart';

ElevationProfile buildElevationProfile(
  List<GeoPoint> elevatedPoints, {
  required String source,
  double noiseThresholdMeters = 2,
}) {
  if (elevatedPoints.length < 2 ||
      elevatedPoints.any((point) => point.elevationMeters == null)) {
    return const ElevationProfile.unavailable();
  }

  final samples = <ElevationSample>[];
  var cumulativeDistance = 0.0;
  var ascent = 0.0;
  var descent = 0.0;
  var minElevation = elevatedPoints.first.elevationMeters!;
  var maxElevation = elevatedPoints.first.elevationMeters!;

  samples.add(
    ElevationSample(
      point: elevatedPoints.first,
      distanceMeters: 0,
      gradePercent: 0,
    ),
  );

  for (var index = 1; index < elevatedPoints.length; index++) {
    final previous = elevatedPoints[index - 1];
    final current = elevatedPoints[index];
    final segmentDistance = haversineMeters(previous, current);
    cumulativeDistance += segmentDistance;

    final previousElevation = previous.elevationMeters!;
    final currentElevation = current.elevationMeters!;
    final delta = currentElevation - previousElevation;

    if (delta.abs() >= noiseThresholdMeters) {
      if (delta > 0) {
        ascent += delta;
      } else {
        descent += -delta;
      }
    }

    if (currentElevation < minElevation) {
      minElevation = currentElevation;
    }
    if (currentElevation > maxElevation) {
      maxElevation = currentElevation;
    }

    final grade = segmentDistance <= 0
        ? 0.0
        : (delta / segmentDistance * 100).clamp(-60.0, 60.0).toDouble();

    samples.add(
      ElevationSample(
        point: current,
        distanceMeters: cumulativeDistance,
        gradePercent: grade,
      ),
    );
  }

  return ElevationProfile(
    points: List<GeoPoint>.unmodifiable(elevatedPoints),
    samples: List<ElevationSample>.unmodifiable(samples),
    ascentMeters: ascent,
    descentMeters: descent,
    minElevationMeters: minElevation,
    maxElevationMeters: maxElevation,
    isAvailable: true,
    source: source,
  );
}
