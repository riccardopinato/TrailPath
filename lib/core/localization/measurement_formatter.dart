import 'package:flutter/widgets.dart';
import 'package:trail_path/core/domain/app_preferences.dart';

class MeasurementScope extends InheritedWidget {
  const MeasurementScope({
    required this.units,
    required super.child,
    super.key,
  });

  final DistanceUnitPreference units;

  static DistanceUnitPreference unitsOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<MeasurementScope>()
            ?.units ??
        DistanceUnitPreference.metric;
  }

  @override
  bool updateShouldNotify(MeasurementScope oldWidget) => units != oldWidget.units;
}

extension TrailPathMeasurements on BuildContext {
  DistanceUnitPreference get distanceUnits => MeasurementScope.unitsOf(this);

  String formatDistance(double meters, {int decimals = 1}) {
    if (distanceUnits == DistanceUnitPreference.imperial) {
      final miles = meters / 1609.344;
      if (miles < 0.1) {
        return '${(meters * 3.280839895).round()} ft';
      }
      return '${miles.toStringAsFixed(decimals)} mi';
    }

    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(decimals)} km';
  }

  String formatElevation(double meters, {bool signed = false}) {
    final value = distanceUnits == DistanceUnitPreference.imperial
        ? meters * 3.280839895
        : meters;
    final prefix = signed && value >= 0 ? '+' : '';
    final unit = distanceUnits == DistanceUnitPreference.imperial ? 'ft' : 'm';
    return '$prefix${value.round()} $unit';
  }

  String formatAccuracy(double meters) {
    final value = distanceUnits == DistanceUnitPreference.imperial
        ? meters * 3.280839895
        : meters;
    final unit = distanceUnits == DistanceUnitPreference.imperial ? 'ft' : 'm';
    return '±${value.round()} $unit';
  }

  String formatPace({
    required Duration elapsed,
    required double distanceMeters,
  }) {
    if (distanceMeters < 50 || elapsed.inSeconds <= 0) {
      return '--';
    }

    final unitMeters = distanceUnits == DistanceUnitPreference.imperial
        ? 1609.344
        : 1000.0;
    final secondsPerUnit =
        elapsed.inSeconds / (distanceMeters / unitMeters);
    final minutes = secondsPerUnit ~/ 60;
    final seconds = secondsPerUnit.round().remainder(60);
    final suffix =
        distanceUnits == DistanceUnitPreference.imperial ? '/mi' : '/km';
    return '$minutes:${seconds.toString().padLeft(2, '0')} $suffix';
  }

  String formatTemperature(double celsius) {
    if (distanceUnits == DistanceUnitPreference.imperial) {
      return '${(celsius * 9 / 5 + 32).round()}°F';
    }
    return '${celsius.round()}°C';
  }

  String formatPrecipitation(double millimeters) {
    if (distanceUnits == DistanceUnitPreference.imperial) {
      return '${(millimeters / 25.4).toStringAsFixed(2)} in';
    }
    return '${millimeters.toStringAsFixed(1)} mm';
  }

  String formatSpeed(double kilometersPerHour) {
    if (distanceUnits == DistanceUnitPreference.imperial) {
      return '${(kilometersPerHour * 0.621371192).toStringAsFixed(0)} mph';
    }
    return '${kilometersPerHour.toStringAsFixed(0)} km/h';
  }

  String formatTargetDistance(double value) {
    final unit = distanceUnits == DistanceUnitPreference.imperial ? 'mi' : 'km';
    return '${value.toStringAsFixed(0)} $unit';
  }

  double targetDistanceMeters(double displayValue) {
    return displayValue *
        (distanceUnits == DistanceUnitPreference.imperial ? 1609.344 : 1000.0);
  }
}
