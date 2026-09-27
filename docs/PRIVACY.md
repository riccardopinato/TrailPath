# TrailPath privacy notice — release candidate

## Data model

TrailPath is local-first. Saved routes, recorded activities, offline readiness,
Back to Car position and app settings are stored on the device in the local Drift
database. The Android app disables platform backup and device-transfer extraction
for this user data.

TrailPath v1.0 has no account, advertising SDK, analytics SDK or cloud sync.
The post-v1 development train adds optional Google account + Supabase Cloud Sync,
both disabled when runtime configuration is absent. There is still no advertising
or analytics SDK.

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


## Optional account and cloud sync

TrailPath remains local-first. Google account sign-in and Supabase Cloud Sync are optional and are disabled when their runtime configuration is absent.

When a user explicitly signs in and enables/uses Cloud Sync, TrailPath may send the following to the configured Supabase project under that authenticated user's row-level-security scope:

- saved route metadata, geometry and waypoints;
- completed activity metadata and recorded geometry;
- selected app preferences that are intended to follow the user across devices;
- Route Collections and their saved-route membership.

Recording drafts, live GPS samples that have not become completed activities, native offline map tiles and the saved Back-to-Car point are not part of the current cloud-sync payload.

The mobile app must use only a Supabase **publishable** client key. A service-role/secret key must never be bundled in the application.

Signing out of Google/Supabase does not delete the local Drift database. Account deletion and server-side data deletion are separate explicit operations that must be provided/configured before public cloud-account rollout.
