# TrailPath roadmap

## Completed foundations

- **v0.1** architecture, database, localization, themes and CI.
- **v0.2** MapLibre map, GPS and location permissions.
- **v0.3** planner, activity profiles, undo/redo and persistence.
- **v0.4** elevation profile and ascent/descent.
- **v0.5** GPX import/export/share.
- **v0.6** foreground/background track recording, autosave and recovery.
- **v0.7** route-following navigation, off-route detection and TTS/haptics.
- **v0.8** MapLibre offline regions.
- **v0.9** battery modes, Back to Car, safety checks and location sharing.
- **v0.9.1** runtime recovery, production basemap and Android smoke testing.
- **v0.9.2** deep runtime audit, lifecycle/permission/offline hardening and AppLab Android gate.

## v0.9.3 - Outdoor Map, Footpath Routing & Release Hardening

- explicit routing failure instead of silent straight-line fallback;
- MapLibre trail/footpath/track feature selection in Planner;
- waypoint projection onto the selected trail segment;
- stronger outdoor path rendering on every live map;
- in-place map overlay updates and throttled camera following;
- committed Android/iOS projects and `pubspec.lock`;
- no unnecessary Android background-location permission;
- stale recording-draft cleanup and safer start ordering;
- removal of unused GoRouter and placeholder MapEngine layers;
- release APKs split by ABI, AAB output, debug-info split and size budget;
- AppLab smoke gate retained for real Android execution.

## v0.9.4 - True Navigation

- request and parse routing maneuver steps;
- turn-by-turn instruction model;
- localized maneuver TTS;
- better heading source for stationary Back to Car;
- stronger network-loss and long background GPS tests.

## v1.0 - Release

Onboarding, accessibility/performance QA, store metadata/signing, optional backup/sync and final release validation.
