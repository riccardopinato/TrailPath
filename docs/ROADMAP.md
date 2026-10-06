# TrailPath roadmap

## v0.1 - Strong Foundation
Architecture, database, service boundaries, localization, themes, CI and application shell.

## v0.2 - Map & Position
Real MapLibre map, GPS, heading, follow-user controls, runtime permissions and native background preparation.

## v0.3 - Route Planner
Waypoint editing, direct route geometry, activity profiles, undo/redo, offline distance/duration metrics and local persistence.

## v0.3.1 - Routing & Snap
Provider-backed foot/bike route requests, asynchronous snap-to-network geometry, routing status feedback, provider abstraction and automatic local fallback.

## v0.4 - Elevation
Open-Meteo/Copernicus elevation sampling, interactive profile inspection, ascent/descent, grade calculation, DEM noise filtering and persisted route elevation metrics.

## v0.5 - GPX Engine
GPX 1.1 import/export, track/route fallback parsing, elevation and timestamp preservation, planner import, saved-route export and native Android/iOS share flows.

## v0.6 - Track Recorder
Live GPS track recording, map trace, distance/ascent/pace metrics, pause/resume, Android foreground service support, iOS background location mode, serial autosave, crash recovery, completed activity history and GPX sharing.

## v0.7 - Navigation
Saved-route following, live route projection and progress, remaining distance, off-route/back-on-route hysteresis, arrival detection, map back-to-route connector and localized voice/haptic alerts.

## v0.8 - Offline
MapLibre offline regions, storage controls and fully offline use of prepared routes.

## v0.9 - Outdoor Intelligence
Activity profiles, adaptive GPS battery modes, persistent Back to Car guidance, device safety checks and quick location sharing.

## v0.9.1 - Runtime Recovery
Production basemap, functional place search, real-device navigation lifecycle fixes, resilient TTS, GPS settings recovery, offline-state reconciliation and Android emulator smoke testing.

## v0.9.3 - Trail-first Routing & Planner Hardening
Explicit routing failures, no fake straight-line fallback, snapped OSM foot/bike waypoints, outdoor planner styling, clearer route casing, fewer redundant MapLibre annotation redraws and expanded routing regression tests.

## v0.9.4 - Footpath-style Route Editing
Draggable waypoint annotations, point selection/removal, long-press insertion into the nearest route leg, cached per-leg geometry and partial rerouting of only the affected span with full-route fallback when the cache is not valid.

## v0.9.5 - Advanced Trail Editing
Selectable route annotations, edit-mode highlighting, draggable midpoint handles placed along real routed leg geometry, midpoint-to-waypoint promotion with partial rerouting, and a 60 m safety guard for long-press insertion.

## v0.9.6 - Map & Routing UX Hardening
MapLibre engine pre-warming, faster planner taps, zoom-aware route hit tolerance, live drag preview with haptics, incremental/coalesced annotation updates and display-only simplification for long route geometries.

## v0.9.7 - Trace Mode
Freehand map drawing with live preview, gesture sampling and simplification, OSM network snapping, atomic undo, partial extension rerouting and chunked requests for long waypoint sets.

## v0.9.8 - Release Hardening
Versioned Android native scaffold, deterministic CI builds, R8/resource shrinking, ABI-split release APKs and release artifact size reporting.

## v0.9.9 - Real Web Routing Parity
Browser preview routes against the same OSM foot/bike services as the native planner instead of drawing direct lines, with snapped geometry, distance/duration feedback and web-safe HTTP transport.

## v0.9.10 - Offline Reliability & State Recovery
Native MapLibre region reconciliation on provider startup, database readiness repair, interrupted-download recovery, live restored progress, centralized deletion state and version-derived CI artifact naming.

## v0.9.11 - Routing Resilience & Shared Network Core
One cross-platform OSM routing engine for Android and Web, persistent HTTP client reuse, bounded retry/backoff for transient failures and HTTP 429/5xx responses, Retry-After handling, strict waypoint-snap validation and deterministic network regression tests.

## v0.9.12 - Network Core Completion & API Hygiene
Standards-compliant Retry-After parsing, shared bounded retry primitives, persistent lifecycle-managed Nominatim/Open-Meteo HTTP clients, serialized search requests, elevation retry hardening and deterministic network regression tests.

## v0.9.13 - Production Hardening & Release Consolidation
Release-mode AppLab E2E with process recovery and real routing, incremental recording/navigation MapLibre updates, GPS follow control, Nominatim retry parity, Android toolchain modernization, explicit GPS backup policy, stricter formatting gate, R8 validation and one primary ARM64 release artifact.

## v0.9.14 - Full Web/Core Parity
Replace duplicated Web preview planner state with the real shared planner/domain core, share routing/elevation/search providers, expose the same waypoint editing, Trace Mode and undo/redo behavior on Web, and isolate only platform-specific capabilities such as background GPS and native offline regions.

## v0.9.15 - Release Candidate & Production Readiness
First-run onboarding, accessibility hardening, fail-closed Play Store signing, AAB validation, privacy/security configuration, true no-network AppLab navigation, migration/offline regression evidence, dependency and size review, and final release-candidate audit.

## v1.0 - Certification & Release
Current runtime candidate: **v1.0.0+31**. TrailPath CI **#395** is the current fully green automated baseline for runtime source `8cb9f2be11ddd7eddc39b73cb7a6f1932b7cbcd1`. Automated validation is **PASS**; the Evidence Bundle remains **BLOCKED** by external production gates: store signing, exact ARM64 physical QA, Play Store listing/screenshots review and staged rollout/rollback approval.

### P0 — certification integrity
- [x] fail closed on automated build/test/AppLab failures and distinguish BLOCKED external evidence from CERTIFIED;
- [x] pin AppLab to `16271b3ffa34982a0f04fd118565047e7c09e743` and record harness identity in evidence;
- [x] keep Network/Offline, Persistence/Restart, Configuration/Lifecycle and Background/Doze gates fail-safe;
- [x] run format, analyze, **77 Flutter tests**, ARM64/x86_64 release builds, AAB structure/size gate, API 29 smoke and full API 35 AppLab on build 31;
- [x] build exact Evidence Bundle with ARM64/x86_64 SHA-256 identity;
- [x] complete the 2026-09-27 deep audit: no code-level P0 crash/data-loss blocker found in the automated path.

### P1 — release-quality hardening
- [x] **Planner map-first layout:** empty planner no longer carries the permanent full summary card;
- [x] **Progressive route details:** hidden/compact/expanded states keep the map primary;
- [x] **Destination confirmation:** map tap/search create a temporary candidate before Start/Destination/Add waypoint;
- [x] **Exact selected coordinates:** confirmed markers stay on user-selected coordinates while only route geometry snaps to OSM;
- [x] **Search-to-route parity on mobile:** search and map tap use the same candidate/confirmation state;
- [x] **Planner fluidity first pass:** coalesced annotation sync and visual caching reduce redundant MapLibre platform-channel updates;
- [x] **AppLab planner E2E:** new confirmation flow, save, navigation, offline and restart sequence passes;
- [~] **Selection accuracy / camera padding:** exact coordinates are fixed, but physical QA must verify bottom-edge pin visibility, sheet occlusion and accidental taps on the exact ARM64 artifact;
- [ ] **Physical ARM64 frame budget:** validate startup, pan/zoom, point preview, route editing and waypoint drag on a representative real Android device; emulator Performance Lab is advisory only;
- [x] **Web Preview UX parity:** Web uses the shared planner core, candidate preview/confirmation flow, shared search/routing/map-matching providers, Smart Trace and coalesced incremental MapLibre annotation updates;
- [~] **Full-app accessibility + small-screen pass:** automated 360×640 dp / 130% large-text AppLab matrix passes on v1.5.21; physical TalkBack focus/order, contrast perception and exact-device checks remain open;
- [x] **Android release contract evidence:** CI records resolved min/target SDK and verifies merged foreground/location/notification permission declarations from the ARM64 release artifact;
- [x] **Production routing-provider decision:** development/internal builds may use community OSM/Valhalla endpoints, while store readiness requires a dedicated `VALHALLA_BASE_URL` and does not silently fall back to community OSRM;
- [ ] **Visual regression baseline:** promote an accepted physical/visual checkpoint only after the build-31 UI is approved;
- [ ] complete exact-artifact ARM64 physical QA, store signing, Play metadata/screenshots and rollout review.

### P2 — correctness, resilience and technical debt
- [x] keep ETA semantics consistent after partial reroute: unaffected duration is retained proportionally and the replacement span uses the routing provider duration;
- [x] harden recording finalization failure handling: final snapshots remain retryable after database failure and UI distinguishes save failure from a genuinely short activity;
- [x] replace raw `error.toString()` surfaces on primary user-facing screens with localized user-safe categories while retaining technical controller/service error state for diagnostics;
- [x] localize foreground-service notification text and remaining hardcoded UI/support strings; recording notification copy now follows IT/EN/ES/FR/PT system locale with English fallback, planner/Web support actions are localized;
- [x] add explicit cancel semantics for long offline downloads; active downloads can be cancelled from Routes or Offline, partial region data is removed, database readiness is reset and the route remains restartable. Download-size review remains part of release QA;
- [x] document the data-at-rest threat model: rely on Android app-private storage/file-based encryption plus disabled backup/data extraction for the current scope; do not add SQLCipher until the threat model changes (`docs/SECURITY_DATA_AT_REST.md`);
- [x] upgrade `permission_handler` 12.x → 13.x in a dedicated post-RC compatibility step with permission/background regression; v1.5.11 uses 13.0.2 and compileSdk 37 with release APK permission inspection;
- [x] remove duplicated semantic version source: `pubspec.yaml` is now the sole semantic version source and runtime map/network identity no longer carries a separately maintained version constant;
- [x] broaden behavioral widget coverage for candidate selection and destructive/error states: extracted candidate actions, shared destructive confirmation and navigation safe-error rendering are exercised as real widgets;
- [x] establish upgrade/migration AppLab baseline from a real previous release artifact: v1.5.13 upgrades the pinned v1.5.11+48 x86_64 CI artifact in-place and verifies activity, route geometry, native offline readiness and settings persistence.

### P3 — polish
- [ ] finish top-toolbar declutter if physical testing still finds the map chrome crowded;
- [x] localize OSM search attribution/support copy;
- [x] revisit generic Safe Interaction Crawler discoverability; AppLab run #822 discovers 3 safe actions (Map layers, Search, Profile) and the journey crawler observes 4 states / 6 transitions without runtime failures.

Full detail: `docs/FULL_AUDIT_v1.0.0.md`.


## Post-v1 approved product roadmap

The following items are **approved product scope** after the 2026-09-27 product review. They are not part of the v1.0 release candidate and must not delay certification of the current build unless explicitly promoted to a blocker.

### v1.1 — Smart Trace & Map Experience

Goal: make route creation materially closer to Footpath-quality behavior before adding account/cloud complexity.

- [x] **Smart Trace / Map Matching Engine:** dedicated Valhalla `trace_route` map matching now follows the drawn gesture against the OSM network; Free mode retains the legacy free-form trace path.
- [x] evaluated Valhalla/OSRM/GraphHopper direction; `MapMatchingEngine` keeps the implementation swappable and v1.1 uses Valhalla `trace_route` as the first provider.
- [x] preserve gesture samples as the map-matching trace while returning matched OSM network geometry.
- [x] add drawing modes: Follow trails / Follow roads / Free.
- [x] add route-drawing tools: eraser-last-segment, undo/redo, loop, out-and-back and reverse.
- [x] keep the current distance/elevation engine as the reference implementation after Smart Trace matching.
- [x] **Map layer selector:** Outdoor, Street and High Contrast are free; Satellite and Hybrid are provider-gated Pro styles.
- [x] **Pro satellite layer:** current MapTiler Satellite style is wired through runtime `MAPTILER_API_KEY` and Premium entitlement.
- [x] **Pro satellite + trails overlay:** MapTiler Hybrid is wired behind Premium entitlement and runtime provider configuration.
- [x] evaluate terrain/relief/contours without coupling core planner state to one vendor; v1.5 implements Pro Slope Map from TrailPath elevation data and optional MapLibre 3D terrain from a configured DEM provider.
- [x] **Privacy-safe provider usage hooks:** local aggregate counters/timestamps cover MapTiler Satellite, Hybrid and 3D Terrain sessions; no coordinates, routes or precise-location analytics are stored or transmitted.

### v1.2 — TrailPath Pro

Goal: introduce monetization only after the planner/map experience is strong enough to justify payment.

- [x] implement a **Premium Engine** behind feature entitlements, provider-agnostic and testable.
- [x] integrate official Google Play Billing via `in_app_purchase` behind `PremiumEngine`; RevenueCat is not required by the current architecture.
- [x] monthly/yearly Play products are implemented; proposed launch pricing remains **€2.99/month / €19.99/year** pending Play Console product configuration.
- [x] no Lifetime at launch while satellite/cloud providers create recurring operating cost.
- [x] build a non-blocking paywall with monthly/yearly products, restore purchases and transparent Pro benefits.
- [x] Free remains useful: planning, GPS recording, elevation, GPX, standard/high-contrast maps and basic navigation.
- [x] Pro entitlement now gates Satellite/Hybrid, Route Lab, Collections, Personal Stats, Cloud Sync, Slope Map, 3D Terrain and automatic rerouting; safety/recovery remain free.
- [x] keep critical safety/recovery features outside the Pro paywall.

### v1.3 — Settings, Profile & Account Foundation

Goal: make TrailPath feel like a complete product without forcing account creation.

- [x] create a real **Settings** screen: Metric/Imperial units, default map/activity, GPS mode, theme, voice, Wi-Fi download policy, auto-reroute and privacy are behavior-backed; route/weather/pace displays use the shared measurement scope.
- [x] create a useful **Profile** hub with account state, Pro status, activity/route summary, Outdoor tools, Settings, Route Lab, Collections, Stats and Cloud Sync.
- [x] keep TrailPath fully usable local-first without login.
- [x] optional **Google Sign-In** is config-gated and used only for account-backed Cloud Sync.
- [x] separate identity/auth from local outdoor data; sign-out never silently deletes routes/activities/preferences.
- [x] document account sign-out/local-data retention/cloud deletion lifecycle before production account enablement.
- [x] add authenticated in-app account deletion: server identity/cloud rows are deleted first, then local routes/activities/settings/offline maps are purged; failure remains fail-safe to the local copy. Public deletion instructions live in `docs/ACCOUNT_DELETION.md`.

### v1.4 — Cloud Sync & Cross-device

- [x] optional backup/sync covers routes + waypoints, completed activities, behavior-backed preferences and Route Collections.
- [x] implement last-write-wins conflict resolution, local outbox queueing, remote tombstones and explicit Profile sync status.
- [x] **Cloud security boundary:** Supabase HTTPS/TLS, RLS, authenticated-only table access and publishable client credentials are implemented/documented; provider-managed at-rest encryption/retention is an explicit production-environment approval gate, not falsely claimed as app-side encryption.
- [x] remote-newer records restore into local Drift, deletions propagate through tombstones, and Google/Supabase sign-out does not delete local data.
- [x] route tombstones remove collection membership deterministically and collection records are applied after route state to prevent stale cross-device references.
- [x] no mandatory cloud dependency for planning, recording or navigation; Supabase is runtime-config gated.
- [x] Drift migration regression covers **v1/v2/v3/v4 → v5** while preserving legacy activity data.
- [x] Google ID-token auth does not require a secondary access token; optional token enrichment cannot block cloud authentication.
- [x] Supabase initialization fails closed to local-first availability instead of blocking app startup.

### v1.5 — Premium Outdoor Intelligence

Approved ideas to implement after Smart Trace + Pro foundation:

- [x] **Circular Route Generator:** choose current start + target distance/activity and generate ranked snapped loop options using the existing routing/elevation engines.
- [x] **Alternative Routes:** shortest, least-climb, more-trail and more-road strategies are implemented; surface-aware ranking uses OSM data and preserves unknown coverage.
- [x] **Slope Map / grade overlay:** Pro overlay colors route segments from the existing elevation-grade samples.
- [x] **Surface-aware route info:** OSM/Overpass route-corridor sampling reports paved / gravel / dirt / trail / unknown with unknown preserved when tags are insufficient.
- [x] **Outdoor POIs along route:** drinking water, huts/shelters, parking, viewpoints and toilets from OSM/Overpass, filtered by route distance.
- [x] **Weather along route:** Open-Meteo samples multiple positions along the selected route.
- [x] **Route Collections:** local folders with route membership, Drift v5 persistence and cloud-sync support.
- [x] **Personal stats:** totals, 7/30-day distance, moving time, longest activity and highest-ascent activity.
- [x] recording finalization distinguishes saved / too-short / save-failed and keeps failed finalization retryable without discarding the captured track.
- [x] **Automatic rerouting:** optional Pro preference recalculates from live position to destination after off-route events, with cooldown and safe failure fallback.
- [x] **3D terrain:** Pro MapLibre terrain path is implemented behind configured MapTiler DEM/runtime entitlement; provider cost/performance remains a production acceptance gate.
- [x] harden planner start-state E2E timing while preserving the required `Choose destination` state before second-point routing.
- [x] harden final AppLab semantics/timing: Pro-card matching follows the combined accessibility node and destination confirmation is exercised when surfaced without failing a run that has already reached the valid savable route state.

### v1.5.3 — QA & Production Services Foundation

Goal: convert field feedback from the v1.5 Pro APK into repeatable release gates and prepare the external-service boundary without weakening local-first behavior.

- [x] restore a strict repository formatting gate after canonicalizing the v1.5.3 Dart changes.
- [x] make the main AppLab Outdoor flow locale-tolerant instead of hard-coding the English accessibility label.
- [x] add a dedicated internal-Pro x86_64 artifact and AppLab v1.5 Pro routing gate covering Pro entitlement, live Route Lab generation and Smart Trace road-mode availability.
- [x] add privacy-safe routing diagnostics for OSM, Valhalla and Smart Trace fallback selection without logging route coordinates.
- [x] add live OSM/Valhalla provider smoke coverage and fix the field-discovered Valhalla trace units contract (`kilometers`) that caused HTTP 400 map-matching failures.
- [x] v1.5.3.1 runtime hardening: suppress unsupported MapLibre Native terrain calls on Android/iOS and repair the dedicated Pro Maestro invocation.
- [x] centralize production-service readiness for Google Sign-In, MapTiler, Supabase Cloud Sync and Google Play server verification.
- [x] add optional backend purchase-token verification and require it for a store-signed AAB.
- [x] document the GitHub configuration contract for Google OAuth, premium maps, dedicated TrailPath Supabase and Google Play verification.
- [ ] configure the real external credentials/projects in their provider consoles before production enablement; CI must continue to report missing services instead of embedding placeholders.
- [ ] repeat the physical-device regression on the exact v1.5.21 ARM64 candidate (SHA-256 `6a93b9348413ad52fe7d2138ed03ad0b7b0971c485deb1c0176c8d58ba764af5`); the old v1.5.3/v1.5.2 field-test target is superseded.

### Product principles for the approved roadmap

- REUSE-FIRST: reuse TrailPath service contracts, MapLibre stack, routing/elevation engines, persistence and CI before adding parallel implementations.
- Do not gate core safety, data recovery or basic route ownership behind Pro.
- Paid features must have clear recurring value or recurring provider cost.
- Map/satellite provider licensing and commercial usage limits are a release gate for every premium map layer.
- Account is optional; local-first remains the default architecture.
- Every implemented maxi-step updates README, roadmap, tests and release evidence.
- No post-v1 scope may be merged into the v1.0 certification branch if it destabilizes the current release candidate.


### v1.5.8 — UX parity & user-safe error hardening

- [x] formalize Web Preview parity against the shared planner core and coalesced annotation pipeline;
- [x] replace raw Settings and active Navigation technical errors with localized user-safe messages;
- [x] localize planner OpenStreetMap search attribution across supported languages;
- [x] keep technical failure detail in controller/service state and structured logs instead of rendering raw exceptions directly to users.


### v1.5.9 — Cancellable offline downloads

- [x] active offline downloads can be stopped explicitly from both Routes and Offline screens;
- [x] cancellation terminates the active stream, removes partial region data and resets saved-route offline readiness without deleting the route;
- [x] cancelled downloads remain restartable;
- [x] offline inventory failures are rendered with localized user-safe copy instead of raw exception text;


### v1.5.10 — Primary error-surface hardening

- [x] sanitize Settings, Navigation, Offline, Routes, Recording, Outdoor and Back to Car error rendering;
- [x] add localized user-safe failure copy for the supported languages;
- [x] add an architecture regression test that blocks raw exception rendering on primary screens;


### v1.5.11 — Android permission contract hardening

- [x] upgrade permission_handler to 13.0.2 using request-driven permanently-denied handling;
- [x] compile against Android SDK 37 while leaving targetSdk controlled by the pinned Flutter toolchain;
- [x] add architecture coverage for notification, fine/coarse location and foreground-location permissions;
- [x] add CI inspection of the built ARM64 APK for resolved min/target SDK and merged permission declarations.


### v1.5.12 — Core Consistency & UX Hardening

- [x] make `pubspec.yaml` the single semantic-version source and remove the duplicate `MapConfig.appVersion`;
- [x] localize Android foreground GPS-recording notification copy for IT/EN/ES/FR/PT with English fallback;
- [x] extract planner candidate actions into a behavior-testable widget and cover destination gating, waypoint actions, cancellation and narrow-screen rendering;
- [x] centralize destructive confirmation dialogs and cover cancel/confirm behavior with widget tests;
- [x] add navigation widget coverage proving internal engine errors are not rendered to users;
- [x] remove the remaining Italian-only Web waypoint action and keep Web planner support copy localized.


### v1.5.13 — Real-artifact Upgrade & Migration AppLab

- [x] pin the last fully green v1.5.11+48 x86_64 release artifact as the migration baseline;
- [x] seed completed activity, routed geometry, native offline state and a non-default unit preference through real UI flows before upgrade;
- [x] install the new APK with `adb install -r` and explicitly forbid state clearing during verification;
- [x] verify persisted activity, route navigation geometry, offline readiness and settings after the package update;
- [x] retain upgrade evidence with old/new package identity and SHA-256 values;
- [x] refresh a dedicated 90-day baseline artifact so future migration runs are not tied to the normal one-day x86 runtime artifact.


### v1.5.14 — Audit Closure & Certification Repair

- [x] repair the AppLab System UI process-health race while keeping target ANR/FATAL checks fail-closed;
- [x] protect Pro and migration E2E from foreign emulator ANR dialogs without suppressing TrailPath failures;
- [x] make upgrade/migration failures always emit stage diagnostics and a failure summary;
- [x] include live routing, Pro routing and upgrade/migration in the actual certification verdict instead of only in job dependencies;
- [x] remove hard-coded v1.0 evidence naming from the post-v1 certification bundle;
- [x] make release-mode Pro entitlement fail closed unless purchase verification is server-backed;
- [x] add authenticated account + cloud + local/offline data deletion with regression coverage;
- [x] require a dedicated production Valhalla-compatible provider for store readiness while preserving community providers for development/internal builds;
- [x] close the local GPS data-at-rest decision with a documented Android threat model and explicit review triggers;
- [ ] physical ARM64 performance/TalkBack/small-screen validation and external provider/Play configuration remain real-device/provider-console gates, not code defects.


### v1.5.15 — AppLab Root-Cause Closure

- [x] fix a real compact-accessibility defect: the onboarding primary CTA is pinned outside the scroll body and remains reachable at 360×640 with 130% font scaling;
- [x] add a widget regression proving the onboarding CTA remains inside the constrained viewport;
- [x] classify Maestro device-server death / gRPC UNAVAILABLE / closed forwarded sockets as retryable hosted-emulator infrastructure, with stale ADB forwards cleared during recovery;
- [x] make the v1.5.11 migration seed/verify target the already-visible Flutter Settings semantics directly instead of relying on a brittle scroll selector;
- [x] rerun the complete release matrix after deterministic selector/retry fixes; v1.5.19 proved Core, API29, Pro, UX and Upgrade/Migration green together, isolating the final main-E2E failure to AppLab System UI crash attribution.


### v1.5.16 — Deterministic AppLab & Migration Closure

- [x] prove the main TrailPath E2E user journey itself passes through recording recovery, route creation, navigation, offline persistence and no-network navigation before the later stress-lab failure;
- [x] remove the migration false-negative selector on the localized `Units` label and wait for the concrete persisted preference value instead;
- [x] classify UiAutomation already-registered / bad-file-descriptor failures as harness infrastructure and reset stale Maestro instrumentation + ADB forwards before retry;
- [x] keep small-screen retries alive when the first runtime-recovery pass cannot fully reacquire the hosted emulator;
- [x] define a TrailPath-specific resource/process-death policy with supported foreground trim level and a 5 s recovery settle window;
- [x] fix AppLab Resource Pressure upstream so ANR/FATAL evaluation is scoped to diagnostics emitted after the intentional process kill and relaunch;
- [x] pin the validated AppLab fix commit and isolate the remaining false negatives by evidence.



### v1.5.17 — AppLab Policy & Viewport Root-Cause Fixes

- [x] pass the TrailPath repository root explicitly to AppLab so project-specific lifecycle/resource policies are actually loaded instead of silently falling back to generic defaults;
- [x] add a TrailPath lifecycle policy with one rotation/background cycle and a 5 s settle window, preserving fail-closed crash/ANR checks without artificial one-second platform-view churn;
- [x] fix the small-screen matrix geometry: 720×1280 physical at 320 dpi now yields the intended 360×640 dp Flutter viewport instead of the accidental 180×320 dp viewport;
- [x] prove from migration failure evidence that Flutter exposes the Units dropdown as a combined accessibility node and update seed/verify selectors to match that semantics across IT/EN/ES/FR/PT;
- [x] rerun the complete matrix; v1.5.19 isolated the only remaining failure to AppLab System UI Lab while every other blocking gate passed.


### v1.5.18 — Deterministic AppLab UiAutomation Closure

- [x] remove the logically invalid small-screen assertion that expected a populated `Your routes` section on a fresh profile; the gate now verifies the real localized empty-routes state;
- [x] make migration preference selection independent of Flutter combined-semantics ordering by matching the concrete Metric/Imperial values rather than label/value concatenation;
- [x] stop running AppLab's UiAutomator-based foreign-ANR probe concurrently with Maestro; probes are serialized before each Maestro attempt;
- [x] clear attempt-scoped logcat before Maestro so stale UiAutomation faults cannot misclassify a deterministic assertion as transient infrastructure;
- [x] apply the serialized ANR/UiAutomation contract consistently to Pro, small-screen and upgrade/migration harnesses;
- [x] rerun the full release matrix; Core, API29, Pro, small-screen and Upgrade/Migration passed together on v1.5.19, leaving only the System UI Lab false-positive path.


### v1.5.19 — Deterministic Accessibility / AppLab Closure

- [x] use combined-semantics-safe selectors for Profile → Settings and Units on the 360×640 dp / 130% font-scale matrix;
- [x] prove from AppLab hierarchy evidence that the Settings card remains in the scrollable Profile list and the previous failure was selector mismatch, not missing UI;
- [x] stop classifying deterministic Maestro visibility/assertion failures as transient merely because emulator logs contain unrelated transport noise;
- [x] keep explicit Maestro driver/device failures retryable while preserving fail-closed product assertions;
- [x] automated candidate promotion criterion satisfied by v1.5.21 CI #822: Core, routing, API29, main E2E, Pro, small-screen/large-text and Upgrade/Migration are green in the same run.


### v1.5.20 — AppLab System UI Crash Attribution Closure

- [x] inspect the complete v1.5.19 AppLab evidence bundle instead of relying only on the job exit code;
- [x] prove the v1.5.19 main user journey, visual journey, process restart, API29, Pro, small-screen and real-artifact migration paths are healthy;
- [x] isolate the remaining main-E2E failure to AppLab System UI Lab crash attribution rather than TrailPath runtime behavior;
- [x] fix AppLab to clear pre-lab log history and associate FATAL EXCEPTION only with the target process inside the same AndroidRuntime crash record;
- [x] add upstream AppLab self-tests covering foreign fatal, target fatal and target ANR classification;
- [x] pin every blocking TrailPath AppLab job to the audited AppLab fix commit;
- [x] v1.5.20 promotion requirement superseded and satisfied by the complete v1.5.21 run #822 matrix.


### v1.5.21 — Unified AppLab Android Runtime Attribution

- [x] prove from repeated v1.5.19/v1.5.20 evidence that the remaining blocking failure is AppLab crash attribution, not a TrailPath user-flow/runtime failure;
- [x] replace duplicated broad FATAL/Process regexes across AppLab System, Network, Storage, Persistence, Background, Upgrade, Configuration, Resource Pressure and Interaction Crawler paths with one target-scoped AndroidRuntime classifier;
- [x] bind Android fatal records to the AndroidRuntime emitter PID and require a matching target Process/PID line, preventing Launcher/SystemUI/UiAutomation crashes from being reclassified as TrailPath crashes;
- [x] make the central AppLab verifier consume the same classifier instead of combining unrelated logcat records with grep context;
- [x] persist System UI Lab logcat plus exact crash-attribution evidence for future auditability;
- [x] repair backend diagnostics so an arbitrary AndroidRuntime fatal is not automatically treated as a target-app fatal;
- [x] cover foreign fatal, interleaved foreign/target records, real target fatal and target ANR with AppLab self-tests;
- [x] retain PID stabilization for hosted-emulator process recycling without weakening target ANR/FATAL fail-closed behavior;
- [x] pin all TrailPath blocking AppLab jobs to validated harness commit `d6f2df29099e4744e750480321b15bc04b045d61`;
- [x] promote v1.5.21 automated candidate: CI #822 passes Core/build, live routing, API29, main E2E, Pro routing, constrained UX, real-artifact Upgrade/Migration and Release Certification Evidence in the same run. Production certification remains BLOCKED only by external/physical gates.
