import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/domain/app_preferences.dart';
import 'package:trail_path/core/localization/measurement_formatter.dart';

void main() {
  testWidgets('metric formatting is consistent', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MeasurementScope(
        units: DistanceUnitPreference.metric,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (value) {
              context = value;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(context.formatDistance(500), '500 m');
    expect(context.formatDistance(5000), '5.0 km');
    expect(context.formatElevation(100, signed: true), '+100 m');
    expect(context.formatAccuracy(7), '±7 m');
    expect(
      context.formatPace(
        elapsed: const Duration(minutes: 25),
        distanceMeters: 5000,
      ),
      '5:00 /km',
    );
    expect(context.formatTemperature(20), '20°C');
    expect(context.formatPrecipitation(2.54), '2.5 mm');
    expect(context.formatSpeed(10), '10 km/h');
    expect(context.targetDistanceMeters(10), 10000);
  });

  testWidgets('imperial formatting converts distance pace and weather', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MeasurementScope(
        units: DistanceUnitPreference.imperial,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (value) {
              context = value;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(context.formatDistance(1609.344), '1.0 mi');
    expect(context.formatElevation(100), '328 ft');
    expect(context.formatAccuracy(3), '±10 ft');
    expect(
      context.formatPace(
        elapsed: const Duration(minutes: 8),
        distanceMeters: 1609.344,
      ),
      '8:00 /mi',
    );
    expect(context.formatTemperature(20), '68°F');
    expect(context.formatPrecipitation(25.4), '1.00 in');
    expect(context.formatSpeed(16.09344), '10 mph');
    expect(context.targetDistanceMeters(10), closeTo(16093.44, 0.01));
  });
}
