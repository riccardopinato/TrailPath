# TrailPath v1.0.0 certification checklist

Status values are limited to **Pass**, **Fail**, **N/A** and **Not Tested**.
Unknown items are never treated as passed.

| Area | Status | Evidence / requirement |
| --- | --- | --- |
| Product scope | Pass | v1.0.0 is feature-frozen; this branch contains certification/release operations only. |
| Versioning | Pass | pubspec 1.0.0+28 and MapConfig 1.0.0. |
| First-run onboarding | Pass | Widget test passed and AppLab completed first-run onboarding plus persisted post-restart state on the RC branch. |
| Formatting | Pass | Strict Dart formatting gate passed on the RC branch. |
| Static analysis | Pass | flutter analyze passed on the RC branch. |
| Full Flutter tests | Pass | Full flutter test suite passed on the RC branch. |
| ARM64 release APK | Pass | Optimized ARM64 release build completed in CI. |
| x86_64 R8 runtime APK | Pass | Optimized x86_64 release runtime build completed in CI. |
| Release AAB structure | Pass | Unsigned/debug-fallback structural release AAB gate completed in CI; store publishing still requires store-signed artifact. |
| Store-signed AAB | Not Tested | Requires the four repository signing secrets; CI fails closed when store signing is explicitly required. |
| AppLab release E2E | Pass | v0.9.15 final gate passed the full release-mode AppLab journey; v1.0.0 certification rerun required on the exact candidate. |
| Recording recovery | Pass | RC AppLab reached recovered recording, resume, completion and persisted activity before the offline split. |
| Saved route navigation | Pass | RC AppLab opened saved-route navigation and verified Remaining/Progress before the offline split. |
| Offline map download + restart | Pass | RC AppLab completed the MapLibre download and verified Available offline after process restart. |
| Navigation with network disabled | Pass | Focused persisted-state airplane-mode flow passed in the final v0.9.15 gate; v1.0.0 exact-candidate rerun required. |
| Database migrations v1/v2 → v3 | Pass | Migration regression tests are included in the full passing Flutter suite. |
| Database schema change | N/A | v0.9.15 does not change Drift schema version 3. |
| Android backup/device transfer | Pass | Manifest disables backup and data-extraction rules exclude app data. |
| Cleartext HTTP | Pass | Android runtime explicitly disables cleartext traffic. |
| Privacy documentation | Pass | docs/PRIVACY.md reflects current local/network behavior. |
| Store signing configuration | Pass | Release Gradle config supports external credentials and fail-closed store mode. |
| Accessibility custom map actions | Pass | 48×48 targets, explicit Semantics/Tooltip/live-region behavior and a regression contract test are present. |
| Dependency freshness | Pass | Audit completed: permission_handler 12.0.3 has a 13.0.2 major available; major upgrade deliberately deferred beyond RC to avoid permission/API churn. Remaining reported items are transitive. |
| APK/AAB size review | Pass | CI enforces a 40 MiB ARM64 budget; exact v1.0.0 size/hash will be captured in the Evidence Bundle. |
| Real-device physical QA | Not Tested | Requires installation on a physical Android device after RC artifact is available. |
| Play Store listing/screenshots | Not Tested | Store metadata draft and screenshot plan exist; screenshots must come from the exact certified physical-device build. |
| Staged rollout / rollback plan | Pass | docs/STAGED_ROLLOUT_v1.0.0.md defines staged rollout, pause criteria and rollback/hotfix path. |

## Release blockers

A **Fail** in formatting, analysis, tests, release builds, AppLab, migration
integrity, offline navigation, privacy configuration or required store signing
blocks release. Store metadata and physical-device QA may remain Not Tested only
until the final v1.0 release gate; they cannot remain Not Tested for production.


## Certification verdict

**BLOCKED**

Automated technical certification is being run on v1.0.0+28. Production certification cannot become **CERTIFIED** until all of the following are closed with evidence:

1. Store-signed AAB built and verified from the release candidate.
2. Physical-device QA completed on the exact candidate artifact.
3. Final Play Store screenshots/metadata reviewed from that exact certified build.

A public v1.0.0 tag/release must not be created while the verdict is BLOCKED.
