# TrailPath data-at-rest decision

## Scope

TrailPath stores routes, recorded activities, preferences and Back-to-Car
coordinates in its local Drift/SQLite database. The Android release also
disables application backup and data extraction, and the operating system
protects app-private storage with the application sandbox and device/file-based
encryption when the device is locked.

## Decision

TrailPath does **not** add a second SQLCipher-style database encryption layer
for the current Android release.

The threat model treats a normally locked, non-rooted device as protected by
Android file-based encryption and the application sandbox. A second application
encryption layer would require key generation/recovery, migration and failure
handling whose data-loss and support cost is not justified by the current
local-first product scope.

This decision does not claim protection against an attacker who controls an
unlocked/rooted device or can extract process memory. If TrailPath later stores
higher-sensitivity identity/medical data, supports shared-device profiles, or
changes its backup policy, this decision must be reviewed.

## Required controls

- Android application data remains non-exported/private by default.
- Android backup/data extraction remains disabled for TrailPath.
- Secrets/service-role credentials are never embedded in the client.
- Cloud data is scoped by Supabase RLS to the authenticated user.
- Account deletion removes both cloud-owned data and local user data.
- Production Play entitlements require server verification.
