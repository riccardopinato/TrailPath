# TrailPath

TrailPath is an outdoor route utility focused on fast planning, reliable track recording and navigation that remains useful when connectivity disappears.

## Current version

v1.0.0 - Certification & Release (build 29)

TrailPath v1.0.0 is the first stable Android release candidate. No new product scope is added here: the milestone is limited to final regression, artifact certification, release evidence and production-readiness gates.

### Current certification status

**RE-CERTIFICATION CANDIDATE — v1.0.0+29.** The previous +28 candidate is NOT CERTIFIED. Build 29 fixes certification integrity, pins the exact AppLab harness, couples saved-route deletion with native offline-region cleanup, and must rerun the complete API 29/API 35 matrix before any merge or release decision.

The automated verdict is authoritative only in the Evidence Bundle generated for the exact candidate SHA. Production remains blocked until store signing, exact-artifact physical ARM64 QA and final Play Store/rollout approvals are complete. The build-29 remediation is kept under the strict Dart formatting gate.

### Included

- Flutter Android codebase with versioned native Android scaffold; iOS release is outside this Android v1.0 certification scope
- Riverpod dependency injection and state foundation
- GoRouter navigation foundation
- Drift local database schema v3 with recoverable activity drafts, return points and app settings
- Map, routing, elevation, location, recording, navigation, offline, GPX and safety contracts
- live MapLibre map in the planner
- live GPS position with accuracy and heading
- planner GPS tracking now follows app lifecycle: UI-only location streams stop outside the foreground and resume only when TrailPath is active
- user-location compass rendering and recenter control
- Android/iOS native location permission setup
- tap-to-add waypoint planning with MapLibre annotations
- draggable waypoint editing with tap selection and removal
- long-press insertion into the nearest route leg
- per-leg route geometry cache for partial rerouting after edits
- selectable route line with visible edit mode
- draggable midpoint handles placed halfway along each routed leg
- guarded long-press insertion with zoom-aware pixel tolerance
- live blue drag preview and haptic feedback before partial rerouting
- incremental MapLibre annotation updates instead of full clear/recreate cycles
- display-only long-route simplification while preserving full routing/GPX geometry
- MapLibre engine pre-warming and planner-only line/circle annotation managers
- faster planner taps with double-click zoom disabled
- freehand Trace Mode with live on-screen route sketching
- gesture sampling, geographic simplification and waypoint-density control
- one trace gesture maps to one planner Undo operation
- existing snapped routes can be extended by tracing with partial rerouting
- long waypoint sets are split into overlapping routing chunks before OSM requests
- chunk failures remain explicit; no silent straight-line replacement
- route line, undo/redo and clear controls
- activity profiles with foot/bike routing profiles
- asynchronous snap-to-network routing through routing.openstreetmap.de
- shared Android/Web routing implementation with persistent HTTP client reuse
- bounded retry/backoff for HTTP 408/425/429/5xx and transient network timeouts
- Retry-After handling and strict snapped-waypoint response validation
- explicit routing failure state when network routing is unavailable; no silent straight-line route can be saved
- Open-Meteo/Copernicus terrain elevation sampling up to 100 points
- ascent/descent and segment grade calculation with DEM noise filtering
- interactive elevation profile with drag inspection
- GPX 1.1 parser/exporter with track, route and waypoint fallback
- native .gpx file import through the platform file picker
- elevation/time preservation on GPX round-trip
- GPX sharing from both planner and saved routes
- separate waypoint and snapped-geometry persistence in Drift
- saved-routes list with delete flow
- live map-first track recorder with distance, ascent, pace and GPS accuracy
- coalesced incremental MapLibre track updates with display-only simplification for long recordings
- foreground/background GPS recording on Android and iOS
- pause/resume, 5-second/point-based autosave and crash recovery
- completed activity history with GPX sharing and deletion
- saved-route navigation with live progress and remaining distance
- static navigation route layer with incremental GPS/off-route updates and user-controlled GPS follow
- off-route / back-on-route hysteresis and arrival detection
- visual back-to-route connector on the map
- localized TTS and haptic navigation alerts
- per-route MapLibre offline map preparation
- adaptive offline-region bounds and zoom levels to control storage size
- live offline download progress and persistent route readiness
- offline map library with storage usage, deletion and ambient-cache controls
- Performance / Balanced / Saver GPS battery modes that alter real sampling behavior
- persistent Back to Car parking point with local distance and bearing guidance
- dedicated Back to Car map with live return line and heading-aware direction arrow
- device Safety Check for battery, system battery saver, GPS permissions/services and offline-map readiness
- quick current-position sharing through the native share sheet
- OpenFreeMap Liberty basemap for navigation/offline screens plus Fiord outdoor styling in the planner
- user-triggered place/trail search with cached, rate-limited geocoding and bounded transient retry/backoff
- navigation startup moved to a safe localization lifecycle
- TTS/haptic feedback isolated so voice failures cannot stop GPS navigation
- live battery-mode reconfiguration for active recording and navigation
- GPS permission/service recovery through Android/iOS system settings
- Android runtime notification/location permission preparation before recording
- battery policies now drive native Android GPS sampling intervals during navigation and Back to Car
- navigation lifecycle regression test covering the previous localization startup crash
- offline readiness reconciled against actual native MapLibre regions
- offline region state restored into Riverpod after app/process restart
- interrupted offline downloads remain visible and can be restarted safely
- CI APK artifact names derive automatically from the pubspec version
- release-mode AppLab Android E2E gate covering recording recovery, persisted activities, real routing, saved-route navigation, completed offline download and restart persistence
- focused offline/no-network Maestro gate with fail-closed assertions and bounded retry only for recognized transient ADB/Maestro infrastructure failures
- Android API 29 release smoke plus API 35 full AppLab certification matrix
- committed Android Gradle/manifest scaffold for reproducible builds
- R8/resource shrinking in release builds
- single ARM64 release APK artifact for normal distribution plus an ephemeral x86_64 R8 runtime artifact for CI
- light and dark outdoor themes
- Italian, English, Spanish, French and Portuguese localization foundation
- structured logging
- tests
- GitHub Actions for format, analyze, test, ARM64/x86_64 release builds, AAB validation, API 29 smoke, API 35 AppLab E2E and certification evidence

## Toolchain

The CI is pinned to Flutter 3.47.5 / Dart 3.13.4, Gradle 9.1.0, Android Gradle Plugin 9.0.1 and Kotlin Gradle Plugin 2.3.20. Built-in Kotlin is temporarily opted out because Flutter 3.47.x currently rejects AGP 9's bundled Kotlin 2.2.10 during dependency validation.

The Android native scaffold is committed and validated by CI for reproducible builds. iOS is not part of the Android v1.0 certification and remains a later release track. The current public routing endpoint is suitable for development and validation; the RoutingEngine abstraction is intentionally kept provider-agnostic so a production-grade or self-hosted service can replace it without changing the planner.

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
