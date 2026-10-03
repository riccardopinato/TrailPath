# TrailPath account deletion

TrailPath provides account deletion directly inside the app.

## Delete from the app

1. Open **Profile**.
2. Sign in to the Google account linked to TrailPath, if needed.
3. In the Google account card, choose **Delete account**.
4. Read the permanent-deletion warning and confirm.

When the configured TrailPath cloud service confirms deletion, TrailPath
permanently removes:

- the TrailPath cloud identity associated with the authenticated user;
- all TrailPath cloud-sync rows owned by that identity;
- locally stored routes, completed activities, collections, preferences and
  return-point data;
- pending cloud-sync mutations;
- downloaded offline map regions and the ambient map cache;
- the local Google/Supabase session.

The operation is irreversible.

If the cloud service cannot confirm deletion, TrailPath intentionally keeps the
local copy instead of destroying the user's only remaining data. Retry the
deletion when connectivity/service availability is restored.

## Web deletion information

This document is the public web reference for TrailPath account deletion and
can be supplied as the account-deletion URL in the Google Play Data safety
configuration. It must remain publicly accessible for any Play Store release
that offers account creation.

TrailPath does not require an account for local planning, recording or
navigation. Deleting a TrailPath cloud account does not delete the user's
Google account.
