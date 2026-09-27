import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/database/app_database.dart';
import 'package:trail_path/core/domain/app_preferences.dart';
import 'package:trail_path/core/domain/models.dart';

void main() {
  test('AppPreferences defaults stay local-first and conservative', () {
    const prefs = AppPreferences();
    expect(prefs.theme, ThemePreference.system);
    expect(prefs.defaultProfile, RouteProfile.hiking);
    expect(prefs.defaultMap, DefaultMapPreference.outdoor);
    expect(prefs.voiceGuidance, isTrue);
    expect(prefs.wifiOnlyDownloads, isFalse);
  });

  test('settings keys are persisted by the database contract', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);

    await database.setSetting('preference_theme', ThemePreference.dark.name);
    await database.setSetting(
      'preference_default_profile',
      RouteProfile.cycling.name,
    );

    expect(
      await database.getSetting('preference_theme'),
      ThemePreference.dark.name,
    );
    expect(
      await database.getSetting('preference_default_profile'),
      RouteProfile.cycling.name,
    );
  });
}
