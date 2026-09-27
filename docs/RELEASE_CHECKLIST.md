# TrailPath v1.0.0 certification checklist

Status values are limited to **Pass**, **Fail**, **N/A** and **Not Tested**.
Historical predecessor evidence is not counted as current-candidate evidence.

Audited runtime candidate: **v1.0.0+31**  
Audited runtime source: **8cb9f2be11ddd7eddc39b73cb7a6f1932b7cbcd1**  
TrailPath CI: **#395 — PASS**  
Pinned AppLab harness: **16271b3ffa34982a0f04fd118565047e7c09e743**

| Area | Status | Evidence / requirement |
| --- | --- | --- |
| Product scope | Pass | v1.0 remains focused on outdoor planning/recording/navigation; no social scope. |
| Versioning | Pass | pubspec 1.0.0+31; semantic UI version 1.0.0. |
| Evidence Bundle truthfulness | Pass | Automated PASS + external BLOCKED status derived from actual gates. |
| AppLab harness identity | Pass | Exact harness SHA pinned and recorded. |
| Formatting | Pass | CI #395, 72 files / 0 changed. |
| Static analysis | Pass | CI #395, no issues found. |
| Full Flutter tests | Pass | CI #395, 77 tests passed. |
| ARM64 release APK | Pass | 33,704,085 bytes; SHA-256 14e198503f1fe4568a2cf4abb69dc4ba7271a6f9985643e7c7185a582f06c38a. |
| x86_64 R8 runtime APK | Pass | AppLab artifact produced/tested. |
| Release AAB structure | Pass | CI #395. |
| ARM64 size budget | Pass | 33.7 MB < 40 MiB gate. |
| Android API 29 release smoke | Pass | install / launch / restart. |
| API 35 AppLab full gate | Pass | complete E2E PASS. |
| Network & Offline Lab | Pass | errors 0 / warnings 0. |
| Persistence & Restart Lab | Pass | 2 cycles, errors 0 / warnings 0. |
| Configuration & Lifecycle | Pass | 6 stages, errors 0 / warnings 0. |
| Background/Doze recovery | Pass | errors 0 / warnings 0. |
| Smart Visual QA | Pass | errors 0 / warnings 0. |
| Visual regression baseline | Not Tested | NO_BASELINE; accept only after physical UI approval. |
| Upgrade/migration AppLab baseline | Not Tested | previous release artifact baseline absent. |
| Database migrations v1/v2 → v3 | Pass | dedicated Flutter migration tests. |
| Saved-route/offline deletion lifecycle | Pass | coordinated native region + DB deletion with regression test. |
| Planner foreground GPS lifecycle | Pass | source regression + API35 lifecycle/background gate. |
| Android backup/device transfer | Pass | disabled/excluded. |
| Cleartext HTTP | Pass | explicitly disabled. |
| Privacy documentation | Pass | current local/network behavior documented. |
| Store-signing configuration | Pass | explicit store mode fails closed. |
| Store-signed AAB | Not Tested | GitHub signing secrets absent. |
| Accessibility custom planner controls | Pass | Semantics/Tooltip/48×48 contract. |
| Full-app accessibility QA | Not Tested | TalkBack/large text/small-screen evidence absent. |
| Physical ARM64 performance baseline | Not Tested | AppLab emulator Performance Lab is WARN/NO_BASELINE. |
| Exact ARM64 physical QA | Not Tested | must use exact evidence hash. |
| Resolved Android SDK/merged FGS artifact evidence | Not Tested | source uses Flutter-resolved values; exact artifact evidence not recorded. |
| Play Store listing/screenshots | Not Tested | final exact-build review required. |
| Staged rollout / rollback review | Not Tested | explicit approval still required. |

## Certification rule

The audited build-31 runtime has **automated validation PASS**. Production remains **BLOCKED** until store signing and every required external production gate are PASS.

A documentation-only audit commit changes the branch SHA and therefore triggers a fresh exact-head CI/evidence cycle. Runtime findings above remain tied to the audited runtime source SHA until the new exact-head run completes.
