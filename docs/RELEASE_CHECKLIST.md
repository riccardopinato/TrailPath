# TrailPath v1.0.0 certification checklist

Status values are limited to **Pass**, **Fail**, **N/A** and **Not Tested**.
Historical predecessor evidence is not counted as current-candidate evidence.

Current candidate: **v1.0.0+30**  
Pinned AppLab harness: **8ccddca7f0f94158483df92d5fd085fe32375de9**

| Area | Status | Evidence / requirement |
| --- | --- | --- |
| Product scope | Pass | v1.0 remains feature-frozen; changes are certification/release hardening only. |
| Versioning | Pass | pubspec 1.0.0+29 and MapConfig 1.0.0. |
| Evidence Bundle truthfulness | Pass | Automated validation is derived from actual build/API29/AppLab results and regression-checked in CI. |
| AppLab harness identity | Pass | Workflow is pinned to the exact SHA above and records it in the Evidence Bundle. |
| Saved-route deletion lifecycle | Pass | Route deletion now removes the linked native offline region before deleting route/waypoints; regression test added. |
| Planner foreground GPS lifecycle contract | Pass | Source regression test exists; runtime certification still required below. |
| Formatting | Pass | Green build-30 certification run. |
| Static analysis | Pass | flutter analyze passed on exact candidate. |
| Full Flutter tests | Pass | Full Flutter suite passed on exact candidate. |
| ARM64 release APK | Pass | Exact candidate built; SHA-256 recorded in Evidence Bundle. |
| x86_64 R8 runtime APK | Pass | Exact AppLab artifact built and exercised. |
| Release AAB structure | Pass | Structural AAB gate passed. |
| ARM64 size budget | Pass | 33,638,317 bytes; below 40 MiB gate. |
| Android API 29 release smoke | Pass | Install/launch/restart passed. |
| API 35 AppLab full gate | Pass | Complete AppLab gate passed. |
| Network & Offline Lab | Pass | Hardened active-connectivity and cold-relaunch checks passed. |
| Focused no-network navigation gate | Pass | Focused airplane-mode Maestro flow passed after AppLab. |
| Background/Doze recovery | Pass | AppLab Background Execution, Doze & Recovery Lab passed with zero errors/warnings. |
| Database migrations v1/v2 → v3 | Pass | Migration tests passed in full Flutter suite. |
| Android backup/device transfer | Pass | Backup disabled and extraction rules exclude app data. |
| Cleartext HTTP | Pass | Explicitly disabled in Android manifest. |
| Privacy documentation | Pass | Current local/network behavior documented. |
| Store-signing configuration | Pass | External signing supported and explicit store mode fails closed. |
| Store-signed AAB | Not Tested | GitHub signing secrets still required. |
| Accessibility custom planner controls | Pass | Semantics/Tooltip/48×48 contract exists. |
| Full-app accessibility QA | Not Tested | TalkBack/large text/full critical-flow evidence not yet recorded. |
| Dependency freshness | Pass | permission_handler major upgrade deliberately deferred beyond RC. |
| Performance baseline | Not Tested | Physical ARM64 profiling still required. |
| Exact ARM64 physical QA | Not Tested | Must use exact candidate SHA/hash. |
| Play Store listing/screenshots | Not Tested | Final exact-build review required. |
| Staged rollout / rollback review | Not Tested | Approval file must be completed for exact candidate. |

## Certification rule

The generated Evidence Bundle for the exact candidate SHA is the authoritative automated verdict. Build 30 automated validation is PASS; current production verdict is BLOCKED by external gates.

- Any required automated failure → **NOT CERTIFIED**.
- All automated gates pass but external production evidence is incomplete → **BLOCKED**.
- Automated gates + store signing + every required external production gate pass → **CERTIFIED**.

No public v1.0.0 tag/release may be created while the verdict is NOT CERTIFIED or BLOCKED.
