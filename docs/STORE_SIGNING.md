# TrailPath Android store signing

TrailPath keeps signing credentials outside the repository.

## Required GitHub Actions secrets

Configure these repository secrets before producing a Play Store artifact:

- `TRAILPATH_KEYSTORE_BASE64` — base64-encoded upload keystore
- `TRAILPATH_STORE_PASSWORD`
- `TRAILPATH_KEY_ALIAS`
- `TRAILPATH_KEY_PASSWORD`

The normal release APK used by CI/AppLab may fall back to the Android debug key when
store credentials are intentionally absent. This keeps release/R8 runtime testing
possible without exposing production credentials.

A store build is different: CI sets `TRAILPATH_REQUIRE_STORE_SIGNING=true`.
Gradle then fails closed unless every credential is present and the keystore file
exists. It must never silently publish an AAB with the debug key.

## Local store build

Provide the four signing values as environment variables, including an absolute
`TRAILPATH_STORE_FILE` path, then run:

`flutter build appbundle --release`

with `TRAILPATH_REQUIRE_STORE_SIGNING=true`.

Do not commit keystores, passwords, `key.properties`, or decoded secret files.
The repository .gitignore already excludes common Android keystore formats.
