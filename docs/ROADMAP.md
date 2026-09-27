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
- [ ] **Web Preview UX parity:** migrate `lib/web_preview.dart` from immediate tap mutation/separate search marker to the same preview/confirmation flow as mobile and carry over annotation caching/coalescing;
- [ ] **Full-app accessibility + small-screen pass:** TalkBack, large text, contrast, compact route summary and candidate actions across critical screens;
- [ ] **Android release contract evidence:** record resolved compile/min/target SDK and merged foreground-location service declarations from the release artifact;
- [ ] **Production routing-provider decision:** explicitly accept the public routing.openstreetmap.de dependency or switch/self-host behind the existing `RoutingEngine` contract;
- [ ] **Visual regression baseline:** promote an accepted physical/visual checkpoint only after the build-31 UI is approved;
- [ ] complete exact-artifact ARM64 physical QA, store signing, Play metadata/screenshots and rollout review.

### P2 — correctness, resilience and technical debt
- [ ] keep ETA semantics consistent after partial reroute: patched legs currently recompute ETA with local static profile speed instead of provider duration;
- [ ] harden recording finalization failure handling: a database completion failure after recorder stop must remain retryable/recoverable and must not surface as “activity too short”;
- [ ] replace raw `error.toString()` surfaces with localized user-safe categories while preserving technical detail in structured logs;
- [ ] localize foreground-service notification text and remaining hardcoded UI/support strings;
- [ ] add explicit cancel semantics for long offline downloads and document/review download-size behavior;
- [ ] decide whether route/activity/Back-to-Car coordinates require app-level encryption at rest;
- [ ] upgrade `permission_handler` 12.x → 13.x in a dedicated post-RC compatibility step with permission/background regression;
- [ ] remove duplicated semantic version source (`MapConfig.appVersion` vs pubspec) or generate it from one source of truth;
- [ ] broaden behavioral widget coverage for candidate selection and destructive/error states; current architecture string-contract tests are useful but brittle;
- [ ] establish upgrade/migration AppLab baseline from a real previous release artifact.

### P3 — polish
- [ ] finish top-toolbar declutter if physical testing still finds the map chrome crowded;
- [ ] localize OSM search attribution/support copy;
- [ ] revisit generic Safe Interaction Crawler discoverability; current crawler finds only one safe action.

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
- [~] **Map layer selector:** Outdoor + Street are live; Satellite + Hybrid are wired as provider-gated styles. Dedicated high-contrast style remains later polish.
- [~] **Pro satellite layer:** MapTiler Satellite is wired through runtime `MAPTILER_API_KEY`; commercial plan/key and entitlement gate complete in v1.2.
- [~] **Pro satellite + trails overlay:** Hybrid provider style is wired; entitlement/licensing gate follows in v1.2.
- [ ] evaluate terrain/relief/contours and future 3D terrain without coupling the app to one map vendor.
- [ ] add explicit map-provider usage/cost telemetry hooks that do not track user routes or precise location analytics.

### v1.2 — TrailPath Pro

Goal: introduce monetization only after the planner/map experience is strong enough to justify payment.

- [ ] implement a **Premium Engine** behind feature entitlements, provider-agnostic and testable.
- [ ] integrate Google Play Billing through a stable abstraction; evaluate RevenueCat only if it materially reduces subscription/restore complexity.
- [ ] proposed launch pricing to validate: **€2.99/month / €19.99/year**.
- [ ] no Lifetime at launch while satellite/cloud providers create recurring operating cost.
- [ ] build a clear, non-blocking paywall with restore purchases and transparent feature comparison.
- [ ] Free remains useful: route planning, GPS recording, elevation, GPX basics, standard maps, basic navigation.
- [ ] Pro candidates: satellite layers, satellite + trails, advanced offline maps, advanced Smart Trace tools, advanced stats, cloud sync, route collections, route generator, terrain/slope layers and future premium map providers.
- [ ] keep critical safety/recovery features out of an aggressive paywall.

### v1.3 — Settings, Profile & Account Foundation

Goal: make TrailPath feel like a complete product without forcing account creation.

- [ ] create a real **Settings** screen for map preference, activity default, units, GPS mode, theme, voice/navigation, download policy and privacy/data controls.
- [ ] create a useful **Profile** surface: account state, Pro status, activity summary, saved-route summary, sync/backup entry point and subscription management.
- [ ] keep TrailPath fully usable local-first without login.
- [ ] optional **Google Sign-In** only when account-backed value exists.
- [ ] separate identity/auth from stored outdoor data so account removal does not silently delete local data.
- [ ] add export/delete-account/data lifecycle documentation before account release.

### v1.4 — Cloud Sync & Cross-device

- [ ] optional backup/sync for routes, activities, preferences and collections.
- [ ] design conflict resolution, offline-first queueing and explicit sync status before implementation.
- [ ] encrypt transport and define at-rest policy for cloud-stored route/location history.
- [ ] restore on new device and sign-out behavior must be deterministic and tested.
- [ ] no mandatory cloud dependency for route recording/navigation.

### v1.5 — Premium Outdoor Intelligence

Approved ideas to implement after Smart Trace + Pro foundation:

- [ ] **Circular Route Generator:** choose start + target distance/activity and generate loop options.
- [ ] **Alternative Routes:** shorter / less climb / more trail / more road, only where routing data supports the distinction.
- [ ] **Slope Map / grade overlay** as a Pro layer.
- [ ] **Surface-aware route info:** asphalt / gravel / trail / road where OSM tagging is reliable.
- [ ] **Outdoor POIs along route:** water, huts, parking, viewpoints, toilets, shelters/bivouacs.
- [ ] **Weather along route** rather than only weather at one coordinate.
- [ ] **Route Collections:** folders/lists for trips, sports or personal organization.
- [ ] **Personal stats:** weekly/monthly distance, elevation gain, duration, activity counts and personal bests.
- [ ] **Automatic rerouting** when off-route, separate from the current warning-only behavior.
- [ ] evaluate **3D terrain** as a Pro visualization after performance/cost validation.

### Product principles for the approved roadmap

- REUSE-FIRST: reuse TrailPath service contracts, MapLibre stack, routing/elevation engines, persistence and CI before adding parallel implementations.
- Do not gate core safety, data recovery or basic route ownership behind Pro.
- Paid features must have clear recurring value or recurring provider cost.
- Map/satellite provider licensing and commercial usage limits are a release gate for every premium map layer.
- Account is optional; local-first remains the default architecture.
- Every implemented maxi-step updates README, roadmap, tests and release evidence.
- No post-v1 scope may be merged into the v1.0 certification branch if it destabilizes the current release candidate.
