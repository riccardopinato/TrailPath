# TrailPath

TrailPath is a Flutter outdoor route utility focused on planning, track recording, route following and offline preparedness.

## Current version

**v0.9.3 — Outdoor Map, Footpath Routing & Release Hardening**

### Current capabilities

- production OpenFreeMap/MapLibre map on Planner, Recorder, Navigation and Back to Car;
- outdoor path emphasis for visible path/pedestrian/track layers;
- user-triggered place/trail search;
- tap-to-add route waypoints;
- **Select trail** mode that queries rendered MapLibre features and snaps a waypoint onto the selected footpath/trail/track;
- OSM foot routing for hiking/walking/trail-running/dog-walk profiles and bike routing for cycling/MTB;
- routing failures are explicit and cannot silently become a saveable straight line;
- interactive elevation profile with ascent/descent and grade;
- GPX import/export/share;
- saved routes and activities in Drift;
- foreground/background GPS track recording with pause/resume, autosave and recovery;
- seven-day stale-draft cleanup;
- route-following navigation with progress, remaining distance and off-route/back-on-route detection;
- localized TTS/haptic alerts;
- MapLibre offline-region download, progress, storage and reconciliation;
- Performance / Balanced / Saver GPS modes;
- persistent Back to Car;
- Safety Check and current-position sharing;
- Italian, English, Spanish, French and Portuguese localization.

## Runtime and map performance

Recorder, Navigation and Back to Car keep MapLibre annotations alive and update them in place instead of clearing/recreating all overlays for every GPS fix. Camera following is throttled to reduce platform-channel work and visible micro-jank.

## Native/release reproducibility

Android and iOS projects plus `pubspec.lock` are committed. CI validates the committed native permissions/configuration.

CI produces:

- debug APK for AppLab;
- release APKs split by ABI;
- arm64 release APK artifact;
- release AAB;
- split debug-info symbols;
- a release-size budget check.

Android intentionally does **not** request `ACCESS_BACKGROUND_LOCATION`; active recording/navigation use foreground location-service behavior.

## Toolchain

CI is pinned to Flutter 3.47.5 / Dart 3.13.4.

## Local validation

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format lib test
flutter analyze
flutter test
flutter build apk --release --split-per-abi
```

## Product principle

Open the app, create or select a route, and go. TrailPath is a utility first, not a social network.

See `docs/ARCHITECTURE.md` and `docs/ROADMAP.md`.
