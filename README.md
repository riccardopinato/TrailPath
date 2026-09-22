# TrailPath

TrailPath is an outdoor route utility focused on fast planning, reliable track recording and navigation that remains useful when connectivity disappears.

## Current version

v0.4.0 - Elevation

TrailPath now enriches routed geometry with terrain elevation, ascent/descent, grade and an interactive elevation profile while keeping routing and elevation providers independently replaceable.

### Included

- Flutter Android + iOS codebase
- Riverpod dependency injection and state foundation
- GoRouter navigation foundation
- Drift local database schema v1
- Map, routing, elevation, location, recording, navigation, offline, GPX and safety contracts
- live MapLibre map in the planner
- live GPS position with accuracy and heading
- user-location compass rendering and recenter control
- Android/iOS native location permission setup
- tap-to-add waypoint planning with MapLibre annotations
- route line, undo/redo and clear controls
- activity profiles with foot/bike routing profiles
- asynchronous snap-to-network routing through routing.openstreetmap.de
- automatic local straight-line fallback when routing is unavailable
- Open-Meteo/Copernicus terrain elevation sampling up to 100 points
- ascent/descent and segment grade calculation with DEM noise filtering
- interactive elevation profile with drag inspection
- separate waypoint and snapped-geometry persistence in Drift
- saved-routes list with delete flow
- recording shell
- light and dark outdoor themes
- Italian, English, Spanish, French and Portuguese localization foundation
- structured logging
- tests
- GitHub Actions for format, analyze, test and debug APK build

## Toolchain

The CI is pinned to Flutter 3.47.5 / Dart 3.13.4.

Android and iOS platform folders are generated from the current Flutter template during CI. Native permissions are then applied by CI. The current public routing endpoint is suitable for development and validation; the RoutingEngine abstraction is intentionally kept provider-agnostic so a production-grade or self-hosted service can replace it without changing the planner.

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
