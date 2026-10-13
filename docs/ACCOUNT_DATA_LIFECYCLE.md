# TrailPath Account & Data Lifecycle

## Local-first baseline

TrailPath does not require an account. Routes, recordings, preferences, offline maps and Back to Car continue to work locally without Google or Supabase configuration.

## Google sign-in

Google Sign-In is optional and config-gated by `GOOGLE_SERVER_CLIENT_ID`. Signing out removes the authenticated identity from the app but does **not** delete local TrailPath data.

## Cloud Sync

Cloud Sync is optional, Pro-gated and config-gated by:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

The app never embeds a Supabase service-role/secret key.

The current sync scope is:
- saved routes + waypoints;
- completed activities;
- behavior-backed cross-device preferences;
- Route Collections and route membership.

Native offline map regions, incomplete recording drafts and Back-to-Car position are device-local.

## Conflict and deletion semantics

- local edits are written to a Drift outbox first;
- sync can fail without losing the local mutation;
- newer timestamps win;
- route/activity/collection deletion creates a remote tombstone so another offline device cannot silently resurrect deleted data;
- downloaded offline-map readiness is device-local and does not advance the route-content sync timestamp.

## New-device restore

After Google/Supabase authentication, remote records newer than local state are imported into Drift. Offline maps are not transferred and must be downloaded again on the new device.

## Account binding safety

The local Cloud Sync state is bound to the first authenticated Supabase user
that syncs it. Signing out does not remove this binding. A different Google
account cannot upload or merge the existing local database until the user
explicitly resolves the local-data/account ownership boundary. This prevents
pending mutations or previously local-only routes from being uploaded to the
wrong account.

## Sign-out

Sign-out:
- closes the Supabase session;
- signs out Google when the user requests account sign-out;
- leaves local routes/activities/preferences/collections intact.

## Account deletion before production rollout

Public account rollout requires an explicit server-side account deletion action that:
1. authenticates the current user;
2. deletes or schedules deletion of that user's cloud rows;
3. revokes/signs out the Supabase session;
4. disconnects Google identity;
5. asks separately whether local device data should also be erased.

Local deletion must never be implicit merely because a remote account was removed.

## Runtime failure behavior

Cloud provider startup is fail-safe. If Supabase configuration is absent, invalid or initialization fails, TrailPath continues in local-first mode and planning/recording/navigation remain usable.

Collection sync processes route state before collection membership and removes memberships for route tombstones so cross-device deletion cannot silently recreate references to deleted routes.

## External production configuration gates

The code path is implemented, but public account/cloud rollout still requires:
- a production Google OAuth configuration;
- a production Supabase project with the documented RLS schema applied;
- privacy/security review of that project's storage/at-rest configuration;
- an authenticated server-side account/cloud-data deletion endpoint.
