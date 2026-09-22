# TrailPath

TrailPath is an outdoor route utility focused on fast planning, reliable track recording and navigation that remains useful when connectivity disappears.

## Current version

v0.2.0 - Map & Position

### Included

- Flutter Android + iOS codebase
- Riverpod dependency injection and GoRouter navigation
- Drift local database schema
- MapLibre live vector map using OpenFreeMap Liberty
- Geolocator-based location engine isolated behind TrailPath service contracts
- runtime location permission states and recovery flows
- live GPS sample stream, accuracy display and map puck
- heading-aware follow-user mode
- map engine pre-warm
- recording and saved-routes shells
- light and dark outdoor themes
- Italian, English, Spanish, French and Portuguese localization
- unit/widget tests
- GitHub Actions format, analyze, test and debug APK build

## Map provider

The v0.2 online basemap uses OpenFreeMap's Liberty style with OpenStreetMap-derived data. The map layer is deliberately isolated so the provider can be replaced or self-hosted later without coupling route planning to one vendor.

## Toolchain

CI is pinned to Flutter 3.47.5 / Dart 3.13.4 and Java 21.

Android and iOS platform folders are generated from the current Flutter template during bootstrap. `tool/configure_native.dart` then applies the foreground location permissions required by TrailPath.

## Bootstrap locally

1. Install Flutter 3.47.5 or a compatible stable version.
2. Run: `flutter create --platforms=android,ios --org com.riccardopinato --project-name trail_path .`
3. Run: `dart run tool/configure_native.dart`
4. Run: `flutter pub get`
5. Run: `dart run build_runner build --delete-conflicting-outputs`
6. Run: `flutter test`
7. Run: `flutter run`

## Product principle

Open the app, create or select a route, and go. TrailPath is designed as a tool first, not a social network.

See `docs/ARCHITECTURE.md` and `docs/ROADMAP.md`.
