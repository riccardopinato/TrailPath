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

## v1.0 - Release
Onboarding, Premium foundation, optional backup/sync, accessibility, performance and store QA.
