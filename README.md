# TrailPath

TrailPath is an outdoor route utility focused on fast planning, reliable track recording and navigation that remains useful when connectivity disappears.

## Current version

v0.1.0 - Strong Foundation

This first baseline establishes the application architecture before routing and live maps are enabled.

### Included

- Flutter Android + iOS codebase
- Riverpod dependency injection and state foundation
- GoRouter navigation foundation
- Drift local database schema v1
- Map, routing, elevation, location, recording, navigation, offline, GPX and safety contracts
- map-first planner shell
- recording and saved-routes shells
- light and dark outdoor themes
- Italian, English, Spanish, French and Portuguese localization foundation
- structured logging
- tests
- GitHub Actions for format, analyze, test and debug APK build

## Toolchain

The CI is pinned to Flutter 3.47.5 / Dart 3.13.4.

Android and iOS platform folders are generated from the current Flutter template during CI until the native configuration becomes customized in v0.2. This avoids committing obsolete Gradle, Kotlin or Xcode templates during the foundation stage.

## Bootstrap locally

1. Install Flutter 3.47.5 or a compatible stable version.
2. Run: flutter create --platforms=android,ios --org com.riccardopinato --project-name trail_path .
3. Run: flutter pub get
4. Run: dart run build_runner build --delete-conflicting-outputs
5. Run: flutter test
6. Run: flutter run

## Product principle

Open the app, create or select a route, and go. TrailPath is designed as a tool first, not a social network.

See docs/ARCHITECTURE.md and docs/ROADMAP.md.
