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

Drift schema v1 stores saved routes, recorded activities and waypoints. Geometry is deliberately represented independently from the map renderer.

## Offline direction

v1 must allow an already saved route, downloaded map region, GPS recording and route-following navigation to remain functional without connectivity. Full offline route calculation is a later engine replacement, not a prerequisite for the first usable releases.
