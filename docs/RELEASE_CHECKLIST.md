# TrailPath v0.9.15 release-candidate checklist

Status values are limited to **Pass**, **Fail**, **N/A** and **Not Tested**.
Unknown items are never treated as passed.

| Area | Status | Evidence / requirement |
| --- | --- | --- |
| Product scope | Pass | v0.9.15 is limited to release-candidate hardening; no new product subsystem. |
| Versioning | Pass | pubspec 0.9.15+27 and MapConfig 0.9.15. |
| First-run onboarding | Pass | Widget test passed and AppLab completed first-run onboarding plus persisted post-restart state on the RC branch. |
| Formatting | Pass | Strict Dart formatting gate passed on the RC branch. |
| Static analysis | Pass | flutter analyze passed on the RC branch. |
| Full Flutter tests | Pass | Full flutter test suite passed on the RC branch. |
| ARM64 release APK | Pass | Optimized ARM64 release build completed in CI. |
| x86_64 R8 runtime APK | Pass | Optimized x86_64 release runtime build completed in CI. |
| Release AAB structure | Pass | Unsigned/debug-fallback structural release AAB gate completed in CI; store publishing still requires store-signed artifact. |
| Store-signed AAB | Not Tested | Requires the four repository signing secrets; CI fails closed when store signing is explicitly required. |
| AppLab release E2E | Not Tested | Primary journey passed before the focused offline split; current-head rerun pending. |
| Recording recovery | Pass | RC AppLab reached recovered recording, resume, completion and persisted activity before the offline split. |
| Saved route navigation | Pass | RC AppLab opened saved-route navigation and verified Remaining/Progress before the offline split. |
| Offline map download + restart | Pass | RC AppLab completed the MapLibre download and verified Available offline after process restart. |
| Navigation with network disabled | Not Tested | Focused persisted-state airplane-mode AppLab flow added; current-head evidence pending. |
| Database migrations v1/v2 → v3 | Pass | Migration regression tests are included in the full passing Flutter suite. |
| Database schema change | N/A | v0.9.15 does not change Drift schema version 3. |
| Android backup/device transfer | Pass | Manifest disables backup and data-extraction rules exclude app data. |
| Cleartext HTTP | Pass | Android runtime explicitly disables cleartext traffic. |
| Privacy documentation | Pass | docs/PRIVACY.md reflects current local/network behavior. |
| Store signing configuration | Pass | Release Gradle config supports external credentials and fail-closed store mode. |
| Accessibility custom map actions | Pass | 48×48 targets, explicit Semantics/Tooltip/live-region behavior and a regression contract test are present. |
| Dependency freshness | Not Tested | Informational `flutter pub outdated --no-dev-dependencies` gate added; current-head report pending review. |
| APK/AAB size review | Pass | Previous RC ARM64 artifact measured 33,638,317 bytes; CI now enforces a 40 MiB ARM64 budget. |
| Real-device physical QA | Not Tested | Requires installation on a physical Android device after RC artifact is available. |
| Play Store listing/screenshots | Not Tested | Final v1.0 release task. |
| Staged rollout / rollback plan | Not Tested | Final v1.0 release task. |

## Release blockers

A **Fail** in formatting, analysis, tests, release builds, AppLab, migration
integrity, offline navigation, privacy configuration or required store signing
blocks release. Store metadata and physical-device QA may remain Not Tested only
until the final v1.0 release gate; they cannot remain Not Tested for production.
