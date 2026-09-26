# TrailPath v1.0.0 certification checklist

Status values are limited to **Pass**, **Fail**, **N/A** and **Not Tested**.
Historical predecessor evidence is not counted as a current-candidate Pass.

Audited candidate: **v1.0.0+28**  
Source SHA before audit documentation: **d87a6e535025c0b6ea3ad9574ef87e302d6777f9**  
Latest audited workflow: **TrailPath CI #368**

| Area | Status | Evidence / requirement |
| --- | --- | --- |
| Product scope | Pass | v1.0 remains feature-frozen; current work is certification/release hardening. |
| Versioning | Pass | pubspec 1.0.0+28 and MapConfig 1.0.0. |
| Formatting | Pass | CI #368. |
| Static analysis | Pass | CI #368. |
| Full Flutter tests | Pass | CI #368. |
| ARM64 release APK | Pass | Exact candidate built successfully; 33,638,317 bytes. |
| x86_64 R8 runtime APK | Pass | Exact runtime candidate built successfully. |
| Release AAB structure | Pass | CI structural AAB gate passed. |
| ARM64 size budget | Pass | Below enforced 40 MiB limit. |
| Android API 29 release smoke | Pass | Install/launch/restart gate passed. |
| API 35 AppLab full gate | Fail | Network & Offline Lab failed; remaining full sequence did not complete. |
| Network & Offline Lab | Fail | Offline state was not confirmed and app runtime/process state was later unhealthy/absent during the offline stage. Root cause remains unresolved. |
| Recording recovery | Pass | Current AppLab main Maestro journey reached recording recovery and completion before Network Lab. |
| Saved route navigation | Pass | Current AppLab main Maestro journey opened saved-route navigation before Network Lab. |
| Offline map download + restart | Pass | Current AppLab main Maestro journey verified persisted Available offline state. |
| Focused no-network navigation gate | Not Tested | Post-AppLab focused offline script was not reached after Network Lab failure. |
| Background/Doze recovery on current SHA | Not Tested | Current AppLab execution stopped before this lab. |
| Database migrations v1/v2 → v3 | Pass | Included in the passing Flutter test suite. |
| Android backup/device transfer | Pass | Backup disabled and data-extraction rules exclude app data. |
| Cleartext HTTP | Pass | Explicitly disabled in Android manifest. |
| Privacy documentation | Pass | Current local/network behavior documented. |
| Store-signing configuration | Pass | External signing supported and explicit store mode fails closed. |
| Store-signed AAB | Not Tested | Required GitHub signing secrets are not configured. |
| Accessibility custom planner controls | Pass | Semantics/Tooltip/48×48 contract test passes. |
| Full-app accessibility QA | Not Tested | TalkBack/large text/full critical-flow evidence not yet recorded. |
| Dependency freshness | Pass | Audit recorded; permission_handler major upgrade intentionally deferred beyond RC. |
| Performance baseline | Not Tested | AppLab advisory report has NO_BASELINE and severe emulator jank warning; physical profiling required. |
| Visual regression baseline | Not Tested | Current AppLab reports NO_BASELINE. |
| Saved-route deletion lifecycle | Fail | Database route/waypoints are removed but associated native offline region is not cascaded/reconciled. |
| Exact ARM64 physical QA | Not Tested | Must use the exact candidate hash. |
| Play Store listing/screenshots | Not Tested | Draft exists; final exact-build review required. |
| Staged rollout / rollback review | Not Tested | Plan exists but approval file is still NOT TESTED. |

## Current release blockers

1. API 35 AppLab is red.
2. Current Network & Offline Lab root cause is unresolved.
3. Current candidate has not completed Background/Doze and focused no-network gates.
4. Evidence Bundle currently contains an unconditional automated-validation PASS line and must be corrected.
5. AppLab harness is not pinned to an exact version/SHA.
6. Saved-route deletion can orphan native offline map data.
7. Store-signed AAB is absent.
8. Exact ARM64 physical QA is absent.
9. Play Store listing/screenshots and rollout approval are absent.

## Certification verdict

**NOT CERTIFIED**

This verdict follows `docs/CERTIFICATION.md`: a required automated AppLab gate failed.

Even after the automated failure is resolved, the verdict can only move to **BLOCKED** until store signing and all required external production evidence are present. It can become **CERTIFIED** only when every automated and manual production gate passes for the exact release artifact.

A public v1.0.0 tag/release must not be created in the current state.

See `docs/FULL_AUDIT_v1.0.0.md`.
