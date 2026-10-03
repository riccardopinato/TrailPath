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
    final cloudController = File(
      'lib/features/profile/application/cloud_sync_controller.dart',
    ).readAsStringSync();
    final cloudEngine = File(
      'lib/infrastructure/sync/supabase_cloud_sync_engine.dart',
    ).readAsStringSync();
    final schema = File('docs/SUPABASE_CLOUD_SYNC_SCHEMA.sql')
        .readAsStringSync();
    final app = File('lib/app/app.dart').readAsStringSync();

    expect(home, contains('ProfileScreen()'));
    expect(profile, contains('SettingsScreen()'));
    expect(profile, contains('premiumControllerProvider'));
    expect(google, contains('GoogleSignIn.instance'));
    expect(google, contains('attemptLightweightAuthentication'));
    expect(google, contains('authenticate()'));
    expect(profile, contains('deleteAccountAndData'));
    expect(cloudController, contains('deleteAllUserData'));
    expect(cloudEngine, contains('delete_my_trailpath_account'));
    expect(schema, contains('delete_my_trailpath_account'));
    expect(schema, contains('auth.uid()'));
    expect(schema, contains('delete from auth.users'));
    expect(app, contains('settingsControllerProvider'));
    expect(app, contains('ThemePreference.dark'));
  });
}
