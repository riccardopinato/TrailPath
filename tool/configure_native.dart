import 'dart:io';

void main() {
  _configureAndroid();
  _configureIos();
}

void _configureAndroid() {
  final file = File('android/app/src/main/AndroidManifest.xml');
  if (!file.existsSync()) {
    stderr.writeln('AndroidManifest.xml not found. Run flutter create first.');
    exitCode = 1;
    return;
  }

  var content = file.readAsStringSync();
  const permissions = [
    '<uses-permission android:name="android.permission.INTERNET" />',
    '<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />',
    '<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />',
  ];

  for (final permission in permissions) {
    if (!content.contains(permission)) {
      content = content.replaceFirst(
        '<application',
        '    $permission\n\n    <application',
      );
    }
  }

  file.writeAsStringSync(content);
}

void _configureIos() {
  final file = File('ios/Runner/Info.plist');
  if (!file.existsSync()) {
    stderr.writeln('Info.plist not found. Run flutter create first.');
    exitCode = 1;
    return;
  }

  var content = file.readAsStringSync();
  const key = '<key>NSLocationWhenInUseUsageDescription</key>';
  if (!content.contains(key)) {
    content = content.replaceFirst(
      '</dict>',
      '    $key\n'
      '    <string>TrailPath uses your location to show your position on the map and guide you along outdoor routes.</string>\n'
      '</dict>',
    );
  }

  file.writeAsStringSync(content);
}
