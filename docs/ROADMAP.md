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
No new feature scope. Current candidate: **v1.0.0+29 re-certification**. The previous +28 audit verdict remains **NOT CERTIFIED**.

### P0 — certification integrity
- [x] harden AppLab active-connectivity detection and preserve dedicated network-stage Logcat evidence;
- [x] make Evidence Bundle automated-validation status reflect actual gate results;
- [x] pin the AppLab harness to an exact SHA and record it in evidence;
- [x] keep release checklist status tied only to the exact candidate;
- [x] keep build-29 remediation clean under the strict Dart formatting gate;
- [ ] rerun the complete AppLab sequence so Network/Offline, Background/Doze and focused no-network gates all execute on build 29.

### P1 — release hardening
- [x] cascade native offline-region deletion when a saved route is deleted, with regression coverage;
- establish performance/visual baselines and validate ARM64 performance on a physical device;
- record resolved Android SDK/merged foreground-service contract in release evidence;
- decide/accept a production routing-provider reliability strategy;
- complete exact-artifact ARM64 physical QA, store signing, Play metadata/screenshots and rollout review.

### P2/P3 — post-blocker quality
- broaden accessibility and safe interaction coverage;
- replace raw exception strings with localized user-facing errors;
- upgrade permission_handler after v1 certification with regression tests;
- decide whether local route/activity history requires app-level encryption.

Full detail: `docs/FULL_AUDIT_v1.0.0.md`.
