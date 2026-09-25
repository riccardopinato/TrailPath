# TrailPath privacy notice — release candidate

## Data model

TrailPath is local-first. Saved routes, recorded activities, offline readiness,
Back to Car position and app settings are stored on the device in the local Drift
database. The Android app disables platform backup and device-transfer extraction
for this user data.

TrailPath currently has no account system, advertising SDK, analytics SDK or
cloud sync.

## Location

Location is used only for user-invoked GPS features such as planning around the
current position, recording, saved-route navigation, Back to Car and safety
checks. Android may continue location access through a foreground service while
an active recording/navigation feature requires it.

TrailPath does not upload recorded activity history or the saved Back to Car
point to a TrailPath backend.

## Network services

Some planning operations necessarily send limited request data to external
services:

- map style/tile requests to the configured OpenFreeMap endpoint;
- place-search text and language to the configured Nominatim endpoint;
- selected route waypoints to the configured OpenStreetMap routing endpoint;
- sampled route coordinates to Open-Meteo for elevation lookup.

These services receive the request information required to answer the operation.
TrailPath does not add an account identifier to those requests.

## Sharing

GPX files and current-position text leave the app only when the user explicitly
invokes the platform share flow.

## Offline use

Downloaded MapLibre regions, saved route geometry and recorded activity geometry
remain local. A prepared saved route can be opened for navigation without network
connectivity; route calculation and online search/elevation require connectivity.

## Permissions

The Android release declares Internet, coarse/fine location, foreground-service
location, wake lock and notification permissions. Notification permission is used
for foreground/background GPS service behavior where Android requires it.

## Security posture

Android cleartext HTTP traffic is disabled. Signing secrets and keystores are
excluded from source control and store signing is configured to fail closed when
explicitly required.
