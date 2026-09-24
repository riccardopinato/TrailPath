import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_path/core/database/database_providers.dart';
import 'package:trail_path/core/domain/battery_policy.dart';

final batteryModeProvider =
    AsyncNotifierProvider<BatteryModeController, BatteryMode>(
      BatteryModeController.new,
    );

class BatteryModeController extends AsyncNotifier<BatteryMode> {
  static const _settingKey = 'battery_mode';

  @override
  Future<BatteryMode> build() async {
    final stored = await ref.read(appDatabaseProvider).getSetting(_settingKey);
    for (final mode in BatteryMode.values) {
      if (mode.name == stored) {
        return mode;
      }
    }
    return BatteryMode.balanced;
  }

  Future<void> setMode(BatteryMode mode) async {
    state = AsyncData(mode);
    await ref.read(appDatabaseProvider).setSetting(_settingKey, mode.name);
  }
}
