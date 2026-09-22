import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/domain/battery_policy.dart';

void main() {
  test('performance mode prioritizes GPS precision', () {
    final policy = batteryModePolicy(BatteryMode.performance);

    expect(policy.distanceFilterMeters, 3);
    expect(policy.interval, const Duration(seconds: 3));
    expect(policy.keepCpuAwake, isTrue);
    expect(policy.maxAcceptedAccuracyMeters, 40);
  });

  test('saver mode reduces GPS sampling pressure', () {
    final performance = batteryModePolicy(BatteryMode.performance);
    final saver = batteryModePolicy(BatteryMode.saver);

    expect(saver.distanceFilterMeters, greaterThan(performance.distanceFilterMeters));
    expect(saver.interval, greaterThan(performance.interval));
    expect(saver.keepCpuAwake, isFalse);
    expect(
      saver.maxAcceptedAccuracyMeters,
      greaterThan(performance.maxAcceptedAccuracyMeters),
    );
  });
}
