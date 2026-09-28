# TrailPath production services

TrailPath remains local-first and usable without external credentials. The
following services are optional during development but are required before a
fully enabled Play Store release.

## GitHub Actions configuration

Configure these as repository **Secrets** or **Variables**. Secrets are
preferred for values that should not be printed or copied casually.

| Name | Purpose |
| --- | --- |
| `GOOGLE_SERVER_CLIENT_ID` | Google Sign-In OAuth web/server client ID |
| `MAPTILER_API_KEY` | Satellite, Hybrid and 3D terrain map provider |
| `SUPABASE_URL` | TrailPath Supabase project URL |
| `SUPABASE_PUBLISHABLE_KEY` | TrailPath publishable/anon client key |
| `PREMIUM_VERIFICATION_URL` | HTTPS backend endpoint that validates Google Play purchase tokens |
| `TRAILPATH_KEYSTORE_BASE64` | Play upload keystore |
| `TRAILPATH_STORE_PASSWORD` | Upload keystore password |
| `TRAILPATH_KEY_ALIAS` | Upload key alias |
| `TRAILPATH_KEY_PASSWORD` | Upload key password |

The CI passes the first five values through `--dart-define`. The signing
values are never passed into Dart.

When Play signing credentials are present, the store-AAB job now fails closed
unless all five production service values are also configured. Development and
internal-Pro QA artifacts remain local-first and may intentionally run without
them.

## Google Sign-In

Create Android OAuth credentials for package
`com.riccardopinato.trail_path` using the SHA-1/SHA-256 fingerprints of the
Play signing certificate, plus a Web/Server OAuth client. Put the Web/Server
client ID in `GOOGLE_SERVER_CLIENT_ID`.

## MapTiler

Create a restricted MapTiler key for the TrailPath application and store it as
`MAPTILER_API_KEY`. Without it TrailPath intentionally falls back to the free
OpenFreeMap styles and disables Satellite/Hybrid/3D terrain.

## Supabase

Create a dedicated TrailPath Supabase project. Apply
`docs/SUPABASE_CLOUD_SYNC_SCHEMA.sql`, verify RLS policies, and configure the
project URL and publishable key. Never ship a service-role key in the app.

## Google Play Billing verification

The client product IDs are:

- `trailpath_pro_monthly`
- `trailpath_pro_yearly`

`PREMIUM_VERIFICATION_URL` must accept a JSON POST payload:

```json
{
  "platform": "google_play",
  "productId": "trailpath_pro_monthly",
  "purchaseToken": "<google-play-token>"
}
```

and return HTTP 200 with:

```json
{"valid": true}
```

The backend is responsible for validating the token against Google Play and
for rejecting expired, revoked or mismatched purchases. A production release
can set `TRAILPATH_REQUIRE_SERVER_VERIFICATION=true` to fail closed when the
backend is unavailable.

## QA builds

`TRAILPATH_INTERNAL_PRO=true` is allowed only in dedicated internal QA
artifacts. The normal ARM64/AAB release builds must never receive this define.
