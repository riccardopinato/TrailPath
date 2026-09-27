import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v1.3 Profile Settings and optional Google account are wired', () {
    final home = File('lib/features/home/presentation/home_shell.dart')
        .readAsStringSync();
    final profile = File(
      'lib/features/profile/presentation/profile_screen.dart',
    ).readAsStringSync();
    final google = File('lib/infrastructure/auth/google_account_service.dart')
        .readAsStringSync();
    final app = File('lib/app/app.dart').readAsStringSync();

    expect(home, contains('ProfileScreen()'));
    expect(profile, contains('SettingsScreen()'));
    expect(profile, contains('premiumControllerProvider'));
    expect(google, contains('GoogleSignIn.instance'));
    expect(google, contains('attemptLightweightAuthentication'));
    expect(google, contains('authenticate()'));
    expect(app, contains('settingsControllerProvider'));
    expect(app, contains('ThemePreference.dark'));
  });
}
