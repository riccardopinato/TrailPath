# TrailPath v0.9.15 release-candidate checklist

Status values are limited to **Pass**, **Fail**, **N/A** and **Not Tested**.
Unknown items are never treated as passed.

| Area | Status | Evidence / requirement |
| --- | --- | --- |
| Product scope | Pass | v0.9.15 is limited to release-candidate hardening; no new product subsystem. |
| Versioning | Pass | pubspec 0.9.15+27 and MapConfig 0.9.15. |
| First-run onboarding | Not Tested | Persistent Drift-backed onboarding added; current branch widget/AppLab evidence pending. |
| Formatting | Not Tested | Current branch CI pending. |
| Static analysis | Not Tested | Current branch CI pending. |
| Full Flutter tests | Not Tested | Current branch CI pending. |
| ARM64 release APK | Not Tested | Current branch CI pending. |
| x86_64 R8 runtime APK | Not Tested | Current branch CI pending. |
| Release AAB structure | Not Tested | Current branch CI pending. |
| Store-signed AAB | Not Tested | Requires the four repository signing secrets; CI fails closed when store signing is explicitly required. |
| AppLab release E2E | Not Tested | Current branch gate pending. |
| Recording recovery | Not Tested | Covered by AppLab flow; current branch rerun pending. |
| Saved route navigation | Not Tested | Covered by AppLab flow; current branch rerun pending. |
| Offline map download + restart | Not Tested | Covered by AppLab flow; current branch rerun pending. |
| Navigation with network disabled | Not Tested | New airplane-mode AppLab scenario pending. |
| Database migrations v1/v2 → v3 | Not Tested | Automated migration tests exist; current branch suite pending. |
| Database schema change | N/A | v0.9.15 does not change Drift schema version 3. |
| Android backup/device transfer | Pass | Manifest disables backup and data-extraction rules exclude app data. |
| Cleartext HTTP | Pass | Android runtime explicitly disables cleartext traffic. |
| Privacy documentation | Pass | docs/PRIVACY.md reflects current local/network behavior. |
| Store signing configuration | Pass | Release Gradle config supports external credentials and fail-closed store mode. |
| Accessibility custom map actions | Not Tested | 48×48 targets and explicit semantics added; analyzer/widget evidence pending. |
| Dependency freshness | Not Tested | Review still required after functional gates. |
| APK/AAB size review | Not Tested | CI size output pending. |
| Real-device physical QA | Not Tested | Requires installation on a physical Android device after RC artifact is available. |
| Play Store listing/screenshots | Not Tested | Final v1.0 release task. |
| Staged rollout / rollback plan | Not Tested | Final v1.0 release task. |

## Release blockers

A **Fail** in formatting, analysis, tests, release builds, AppLab, migration
integrity, offline navigation, privacy configuration or required store signing
blocks release. Store metadata and physical-device QA may remain Not Tested only
until the final v1.0 release gate; they cannot remain Not Tested for production.
