# TrailPath v1.0.0 certification checklist

Status values are limited to **Pass**, **Fail**, **N/A** and **Not Tested**.
Historical predecessor evidence is not counted as current-candidate evidence.

Current candidate: **v1.0.0+29**  
Pinned AppLab harness: **9c842837e7efddd27d7fdf600482d75e7f9a2dcb**

| Area | Status | Evidence / requirement |
| --- | --- | --- |
| Product scope | Pass | v1.0 remains feature-frozen; changes are certification/release hardening only. |
| Versioning | Pass | pubspec 1.0.0+29 and MapConfig 1.0.0. |
| Evidence Bundle truthfulness | Pass | Automated validation is derived from actual build/API29/AppLab results and regression-checked in CI. |
| AppLab harness identity | Pass | Workflow is pinned to the exact SHA above and records it in the Evidence Bundle. |
| Saved-route deletion lifecycle | Pass | Route deletion now removes the linked native offline region before deleting route/waypoints; regression test added. |
| Planner foreground GPS lifecycle contract | Pass | Source regression test exists; runtime certification still required below. |
| Formatting | Not Tested | Must pass on exact build-29 candidate. |
| Static analysis | Not Tested | Must pass on exact build-29 candidate. |
| Full Flutter tests | Not Tested | Must pass on exact build-29 candidate. |
| ARM64 release APK | Not Tested | Must be generated from exact build-29 SHA. |
| x86_64 R8 runtime APK | Not Tested | Must be generated from exact build-29 SHA. |
| Release AAB structure | Not Tested | Must pass on exact build-29 SHA. |
| ARM64 size budget | Not Tested | 40 MiB gate remains enforced. |
| Android API 29 release smoke | Not Tested | Must rerun on exact build-29 artifact. |
| API 35 AppLab full gate | Not Tested | Must rerun through every required lab. |
| Network & Offline Lab | Not Tested | Must validate using the pinned hardened AppLab harness. |
| Focused no-network navigation gate | Not Tested | Must run after full AppLab passes. |
| Background/Doze recovery | Not Tested | Must reach and pass on current GPS lifecycle implementation. |
| Database migrations v1/v2 → v3 | Not Tested | Covered by full Flutter suite when rerun. |
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

The generated Evidence Bundle for the exact candidate SHA is the authoritative automated verdict.

- Any required automated failure → **NOT CERTIFIED**.
- All automated gates pass but external production evidence is incomplete → **BLOCKED**.
- Automated gates + store signing + every required external production gate pass → **CERTIFIED**.

No public v1.0.0 tag/release may be created while the verdict is NOT CERTIFIED or BLOCKED.
