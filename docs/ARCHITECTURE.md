# TrailPath architecture

## Goals

TrailPath is local-first and engine-agnostic. UI and stored user data must not depend directly on a single routing, map or elevation provider.

## Layers

### App
Application bootstrap, router, theme and global composition.

### Core
Stable domain models, persistence, localization, logging and service contracts.

### Features
Feature-first presentation and use cases. The initial feature boundaries are planner, recording and routes.

### Infrastructure
Provider-specific implementations. MapLibre, routing providers and future offline engines live behind contracts.

## Engine boundaries

- MapEngine
- RoutingEngine
- ElevationEngine
- LocationEngine
- TrackRecorder
- NavigationEngine
- OfflineMapManager
- GpxService
- SafetyService

A future BRouter or other offline router can replace an online implementation without changing planner screens or stored route entities.

## Data

Drift schema v3 stores saved routes, recorded activities, waypoints, persistent return points and lightweight app settings. Geometry is deliberately represented independently from the map renderer.

## Offline direction

v1 must allow an already saved route, downloaded map region, GPS recording and route-following navigation to remain functional without connectivity. Full offline route calculation is a later engine replacement, not a prerequisite for the first usable releases.


## Outdoor intelligence

Battery modes are domain policies, not UI-only preferences. Recording and navigation resolve the selected policy into native GPS accuracy, distance filters and sampling intervals. Back to Car stores its return point in Drift and computes distance/bearing locally so guidance remains useful without connectivity.


## Shared planner core

From v0.9.14, Android and Web consume the same `RoutePlannerController`,
`RoutePlannerState`, routing engine, elevation engine and place-search provider.

The planner core must stay free of platform-only dependencies. Web-safe planner
providers live in `planner_service_providers.dart`; the native provider graph
re-exports them and adds Android/iOS-only services such as background location,
recording, TTS and native offline regions.

Presentation may adapt to each platform, but waypoint mutations, profile
selection, partial rerouting, undo/redo, route geometry, elevation and search
must not be reimplemented in a parallel Web state machine.
