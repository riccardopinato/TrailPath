# TrailPath architecture

## Goals

TrailPath is a local-first Flutter outdoor utility. User data and core route logic are independent from the concrete map, routing and elevation providers.

## Layers

### App
Application bootstrap, theme and the five-tab shell. The project no longer carries a routing package for a single root route.

### Core
Domain models, geodesic/navigation math, Drift persistence, localization, logging and service contracts.

### Features
Planner, recording, saved routes, offline maps, navigation and outdoor/safety tools.

### Infrastructure
Provider-specific implementations: MapLibre/OpenFreeMap rendering and offline regions, OSM foot/bike routing, Open-Meteo elevation, Geolocator, TTS, GPX and device safety.

## Engine boundaries

- RoutingEngine
- ElevationEngine
- LocationEngine
- TrackRecorder
- NavigationEngine
- OfflineMapManager
- GpxService
- PlaceSearchService
- SafetyService

MapLibre is a presentation/native-map dependency rather than a placeholder MapEngine abstraction. A future BRouter, Valhalla or self-hosted OSRM engine can replace online routing without changing stored route entities.

## Data

Drift schema v3 stores saved routes, recorded activities, waypoints, persistent return points and app settings. Route geometry is stored independently from MapLibre.

## Native configuration

Android and iOS project directories and `pubspec.lock` are committed. CI validates them rather than regenerating platform projects. Android uses a location foreground service permission model without `ACCESS_BACKGROUND_LOCATION`.

## Outdoor map

OpenFreeMap Liberty is the shared production basemap. TrailPath applies a lightweight outdoor emphasis to existing path/pedestrian/track layers on planner, recorder, navigation and Back to Car. Planner can query rendered MapLibre features and snap a waypoint to a selected trail geometry.

## Offline direction

Prepared MapLibre regions, saved route geometry, GPS recording and route-following navigation remain useful without connectivity. Full offline route calculation remains a future routing-engine replacement.

## Runtime policy

Battery modes are domain policies that alter native GPS accuracy, distance filters, intervals and wake-lock behavior. Recording drafts autosave serially and stale interrupted drafts older than seven days are discarded during recovery.
