# TrailPath

TrailPath is an outdoor route utility focused on fast planning, reliable track recording and navigation that remains useful when connectivity disappears.

## Current version

Stable certification baseline: **v1.0.0+31**  
Post-v1 cumulative development candidate: **v1.5.0+36**

### Post-v1 cumulative candidate

The v1.5 branch contains the approved v1.1→v1.5 train: Smart Trace/map layers, TrailPath Pro, Settings/Profile/optional Google account, optional Supabase Cloud Sync, Route Lab, Collections, personal statistics, slope/terrain layers and automatic rerouting. Runtime/provider features remain fail-safe when their commercial configuration is absent.


TrailPath v1.0.0 is the first stable Android release candidate. No new product scope is added here: the milestone is limited to final regression, artifact certification, release evidence and production-readiness gates.

### Current certification status

**AUTOMATED VALIDATION PASS — v1.0.0+31.** TrailPath CI #395 completed successfully on audited runtime source `8cb9f2be11ddd7eddc39b73cb7a6f1932b7cbcd1`: format, analyze, 77 Flutter tests, ARM64/x86_64 release builds, AAB structure/size gate, API 29 smoke and the complete API 35 AppLab E2E matrix are green.

The generated Evidence Bundle verdict is still **BLOCKED**, not CERTIFIED, because store-signing credentials are absent and the exact ARM64 candidate still requires physical-device QA, Play Store listing/screenshots review and staged-rollout/rollback approval.

Exact audited ARM64 candidate: **33,704,085 bytes**, SHA-256 `14e198503f1fe4568a2cf4abb69dc4ba7271a6f9985643e7c7185a582f06c38a`.

Pinned AppLab harness: `16271b3ffa34982a0f04fd118565047e7c09e743`.

The 2026-09-27 deep audit found no code-level P0 crash/data-loss blocker in the automated path. Remaining release-quality work is explicit: physical ARM64 map/selection performance validation, restoration of Web Preview UX parity with the build-31 planner flow, full-app accessibility/small-screen validation, resolved Android SDK/merged foreground-service evidence and a production routing-provider decision. See `docs/FULL_AUDIT_v1.0.0.md`.

### Included

- Flutter Android codebase with versioned native Android scaffold; iOS release is outside this Android v1.0 certification scope
- Riverpod dependency injection and state foundation
- GoRouter navigation foundation
- Drift local database schema v3 with recoverable activity drafts, return points and app settings
- Map, routing, elevation, location, recording, navigation, offline, GPX and safety contracts
- live MapLibre map in the planner
- live GPS position with accuracy and heading
- map-first planner empty state: no permanent summary card until a point/route exists
- unified temporary candidate pin for map taps and place-search results
- explicit Start / Destination / Add waypoint confirmation before route mutation
- confirmed planner waypoints retain the exact user-selected coordinates even when route geometry is snapped to the OSM network
- one-point compact destination prompt and valid-route compact summary bar
- expandable draggable details sheet for profile, elevation, GPS and secondary actions, with save flow opened outside the sheet so dialogs are not swallowed by sheet dismissal
- coalesced annotation sync plus route/waypoint/midpoint visual caches to reduce redundant MapLibre platform-channel updates
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
- shared Android/Web routing engine and planner domain core with persistent HTTP client reuse; Web Preview presentation currently lags the build-31 mobile preview/confirmation UX and is tracked as P1 parity debt
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


## Approved post-v1 direction

After v1.0 certification, approved development moves in this order: **Smart Trace/map layers → TrailPath Pro → Settings/Profile/optional Google account → cloud sync → premium outdoor intelligence**.

The current v1.0 release remains feature-frozen. The approved post-v1 scope is tracked in `docs/ROADMAP.md`; satellite/provider licensing and recurring service cost must be validated before any paid map layer is shipped.

See docs/ARCHITECTURE.md and docs/ROADMAP.md.


## v1.1 development train

The post-v1 branch starts at **v1.1.0+32** with Smart Trace and multi-map foundations.

- Smart Trace uses a dedicated `MapMatchingEngine` and Valhalla `trace_route` map matching for Trail/Road modes instead of converting the finger gesture directly into ordinary route waypoints.
- Free mode preserves the previous trace behavior for deliberate free-form planning.
- Cycling/MTB matching switches between mountain/path-biased and road-biased Valhalla bicycle costing.
- Planner exposes Outdoor, Street, Satellite and Hybrid map choices.
- Satellite/Hybrid are provider-gated through `MAPTILER_API_KEY`; no commercial map key is committed to source.
- Existing distance/elevation pipeline remains the source of truth after matched geometry is accepted.
- The Valhalla public demo endpoint is development/fair-use infrastructure only; production provider strategy remains an explicit release decision.

The v1.1 Dart sources are normalized with the pinned Flutter 3.47.5 formatter before CI validation.

- Loop, out-and-back, reverse and erase-last-segment route tools are available inside Smart Trace mode, reusing the planner undo/reroute pipeline.

**v1.1 Smart Trace feature-complete checkpoint:** map matching, Trail/Road/Free modes, map layers, loop, out-and-back, reverse, eraser-last-segment and undo/redo are implemented; exact-head CI/AppLab validation follows this documentation commit.


## v1.4 Cloud Sync

The v1.4 staging candidate is **v1.4.0+35**.

- Optional Supabase client, initialized only when `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` are supplied.
- Google identity remains the user-facing sign-in; native Google tokens establish a Supabase session only when cloud sync is actually used.
- Local Drift remains the source of truth while offline.
- Schema v4 adds a coalescing sync outbox.
- Route/activity deletes are represented as remote tombstones to avoid deleted data reappearing from another device.
- Routes, completed activities and behavior-backed preferences use last-write-wins timestamps.
- First cloud enablement seeds the outbox from existing local data.
- Cloud Sync is a Pro entitlement but planning/recording/navigation remain fully local without it.
- RLS-safe reference schema is documented in `docs/SUPABASE_CLOUD_SYNC_SCHEMA.sql`.
- No Supabase service-role/secret key is embedded in the app.


## v1.5 Outdoor Intelligence

The full approved post-v1 development train reaches **v1.5.0+36**.

Implemented:
- Circular Route Generator using the existing routing + elevation engines and ranked loop candidates.
- Route alternatives for **shortest**, **least climb**, **more trail** and **more road**, with OSM surface-aware ranking where data is available.
- Pro **Slope Map** rendered from the existing elevation/grade profile.
- Pro **3D Terrain** using a runtime-configured MapTiler Terrain DEM.
- OSM/Overpass route-surface analysis with explicit unknown coverage where tagging is insufficient.
- Outdoor POIs along the route: drinking water, shelters/huts, parking, viewpoints and toilets.
- Open-Meteo weather sampling along multiple route positions.
- Route Collections persisted in Drift schema v5 and included in optional cloud sync.
- Personal statistics: totals, 7/30-day distance, moving time, longest activity and highest ascent.
- Optional Pro automatic rerouting after off-route events, with cooldown and non-destructive failure behavior.
- High-contrast map style as an additional free map option.
- Pro access remains centralized through the Premium Engine; basic route ownership, recording, recovery and safety functions remain free.

Provider-dependent functionality stays fail-safe: no MapTiler key means no Satellite/Hybrid/3D terrain; no cloud configuration means the app remains local-first; Overpass/Open-Meteo failures do not invalidate saved local routes.


## v1.2 TrailPath Pro

TrailPath Pro is implemented behind a provider-agnostic Premium Engine using the official Flutter Google Play Billing integration.

- Monthly and yearly products: `trailpath_pro_monthly` / `trailpath_pro_yearly`.
- Non-blocking paywall with purchase, restore and purchase-completion handling.
- Satellite/Hybrid maps and later premium tools consume one entitlement state.
- Basic planning, route ownership, recording, recovery and safety remain available without Pro.
- Runtime map provider keys are never committed to source.

## v1.3 Settings, Profile & Account

- Settings are behavior-backed: theme, Metric/Imperial units, default activity/map, battery mode, voice guidance, Wi-Fi-only offline downloads and automatic rerouting.
- Profile is the app/account hub and keeps Outdoor tools available without expanding bottom navigation.
- Google Sign-In is optional and runtime-configured through `GOOGLE_SERVER_CLIENT_ID`.
- Sign-out does not remove local TrailPath routes, activities or preferences.
- Metric/Imperial preference is exposed and uses the shared measurement formatter across planner, recording, routes, navigation, Back to Car, Profile/Stats, Collections and Route Lab.

v1.5 Outdoor Intelligence sources and tests are normalized with the pinned Flutter 3.47.5 formatter before staging CI.

The v1.5 analyzer fixes are normalized with the pinned Flutter 3.47.5 toolchain before full CI/AppLab validation.

Surface analysis uses bounded route-corridor probes against Overpass instead of querying the full route bounding box, keeping long-route requests controlled while preserving explicit unknown coverage.

### v1.5 hardening notes

- Cloud/collection conflict hardening removes collection membership when a route tombstone arrives and applies collection records after route state.
- Remote collections ignore route IDs that are not present locally, preventing stale cloud references from resurrecting deleted memberships.
- Google ID token is sufficient for Supabase authentication; a secondary Google access token is optional rather than a sync blocker.
- Invalid/unavailable Supabase initialization cannot prevent TrailPath startup: the app continues local-first.
- Drift migration coverage now includes v1, v2, v3 and v4 databases upgrading to schema v5.
- Surface analysis uses bounded route-corridor Overpass probes rather than a potentially huge full-route bounding box.

Metric/Imperial formatting is shared across planner, elevation, recording pace/GPS accuracy, saved routes, navigation, Back to Car, Profile/Stats, Collections, Route Lab POIs and route weather.

The final Profile keeps TrailPath Pro above account details so entitlement state stays visible without scrolling on compact devices and in AppLab.

AppLab now follows the v1.3+ navigation model through **Profile → Outdoor tools** instead of targeting the removed Outdoor bottom-navigation tab.

Back to Car accuracy rendering uses the shared measurement formatter with valid localized composition in the v1.5 final candidate.

Circular-route unit conversion is captured before async GPS/routing work, keeping the final v1.5 analyzer clean without crossing BuildContext over async gaps.

The final Route Intelligence source is normalized with the pinned Flutter 3.47.5 formatter before exact-head CI/AppLab validation.

Recording finalization now distinguishes **saved / too short / save failed**, keeps a failed final snapshot retryable in-session, and no longer misreports a database save failure as a short activity.

The v1.5 final AppLab path uses explicit Profile/Pro semantics and scroll-aware access to Outdoor tools on compact viewports.

The final Profile accessibility patch is normalized with the pinned Flutter 3.47.5 formatter before exact-head certification.

AppLab planner start transition now accepts the explicit `Start here` candidate step when surfaced while still requiring the canonical one-start-point `Choose destination` state before destination selection; this removes a MapLibre/emulator timing race without bypassing route-state validation.


### Provider usage and cloud security boundaries

- Privacy-safe provider usage counters are local-only and record only provider/capability counts plus the last-use timestamp for MapTiler Satellite, Hybrid and 3D Terrain. No route geometry, coordinates or precise-location analytics are written or transmitted.
- Cloud Sync uses Supabase HTTPS/TLS, RLS and authenticated user-scoped rows with only runtime publishable credentials in the client. TrailPath does not embed a service-role key.
- Supabase project-level at-rest encryption, backups and retention remain deployment controls that must be reviewed before production Cloud Sync is enabled; TrailPath does not claim client-side encryption of cloud payloads.

Final v1.5 provider-usage sources are normalized with the pinned Flutter 3.47.5 formatter before the exact-head CI/AppLab gate.


AppLab v1.5 final hardening accepts the combined accessibility node emitted by the Pro card and treats the second planner candidate like the first: when the explicit Destination action is surfaced it is exercised, while a MapLibre/emulator callback race that has already produced the valid savable route state does not create a false-negative E2E failure.