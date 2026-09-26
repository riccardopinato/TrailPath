# TrailPath v1.0.0 — Full Audit

Audit date: 2026-09-26  
Audited candidate: v1.0.0+28  
Source branch: `release/v1.0.0`  
Source SHA before audit documentation: `d87a6e535025c0b6ea3ad9574ef87e302d6777f9`  
Latest certification workflow audited: TrailPath CI #368

## Executive result

**Verdict: NOT CERTIFIED**

The application core is mature and the normal validation pipeline is healthy: formatting, static analysis, the full Flutter test suite, ARM64/x86_64 optimized release builds, the AAB structure gate, the ARM64 size budget and the Android API 29 smoke test all pass.

The exact v1.0.0+28 candidate is not ready to merge/tag/release because the API 35 AppLab gate failed in the Network & Offline Lab and therefore the remaining full certification path did not complete on this exact candidate. Production signing and the required physical/store gates are also still absent.

No public v1.0.0 tag or production artifact should be created from this state.

## Evidence snapshot

| Area | Result | Audit note |
| --- | --- | --- |
| Dart formatting | PASS | CI #368 |
| flutter analyze | PASS | CI #368 |
| Full Flutter tests | PASS | CI #368 |
| ARM64 release APK | PASS | Exact candidate built successfully |
| x86_64 release APK | PASS | Exact AppLab runtime artifact built successfully |
| Release AAB structure | PASS | CI-only structure gate passed |
| ARM64 size budget | PASS | 33,638,317 bytes, below 40 MiB budget |
| Android API 29 smoke | PASS | Install, launch and restart passed |
| API 35 AppLab | FAIL | Network & Offline Lab stopped the full AppLab sequence |
| Network & Offline Lab | FAIL | Offline state was not confirmed and the app process was later observed absent during the offline stage |
| Focused no-network Maestro gate | NOT TESTED | Not reached after AppLab failure |
| Background/Doze recovery on current SHA | NOT TESTED | Not reached after the Network Lab failure |
| Store-signed AAB | NOT TESTED | Signing secrets not configured |
| Exact ARM64 physical QA | NOT TESTED | Required before production |
| Play listing/screenshots review | NOT TESTED | Required before production |
| Staged rollout review | NOT TESTED | Required before production |

## What is strong

- Clean Flutter architecture with app/core/features/infrastructure separation.
- Riverpod provider graph and explicit service contracts keep map, routing, elevation, location, recording, navigation and offline engines replaceable.
- Local-first Drift persistence with migration tests and recoverable recording drafts.
- Route planning, GPX, recording, navigation, offline regions, Back to Car and safety tooling are implemented rather than represented by placeholders.
- Routing failures remain explicit; the app does not silently replace failed online routing with fake straight-line routes.
- HTTP services use persistent clients, timeouts, bounded retry/backoff and Retry-After handling.
- Android backup/device transfer is disabled for app data and cleartext HTTP is disabled.
- Signing secrets are excluded from source control and store-signing mode fails closed when explicitly required.
- ARM64 release size is controlled by a CI budget.
- API 29 and API 35 are separate validation targets and artifact identity is tracked by SHA-256.

## P0 — certification blockers

### 1. Current API 35 AppLab failure must be isolated and resolved

The current candidate fails the Network & Offline Lab. Evidence shows that airplane mode was requested but validated Internet remained visible in the emulator, followed by the application process being absent during the offline stage. The app successfully ran again after network restoration and the report does not establish a TrailPath fatal exception or ANR as the cause.

This is therefore a **release-blocking unresolved runtime/harness failure**, not yet a proven product crash and not safe to dismiss as infrastructure without a targeted reproduction.

Required action:
- reproduce the Network Lab in isolation;
- distinguish emulator connectivity-state failure from application process termination;
- retain fail-closed behavior;
- rerun the complete AppLab sequence on the exact resulting SHA.

### 2. Evidence Bundle contains an incorrect unconditional PASS statement

The CI Evidence Bundle currently writes:

`Automated validation: PASS`

even when AppLab fails and the resulting verdict is `NOT CERTIFIED`.

This makes the certification artifact internally contradictory.

Required action:
- derive the automated-validation field from validate/build + API29 + AppLab results;
- never emit PASS when any required automated gate failed;
- add a regression check for the generated Evidence Bundle.

### 3. Release checklist is using predecessor evidence as current PASS evidence

The previous checklist marks AppLab and no-network navigation as PASS using v0.9.15 predecessor evidence while also stating that v1.0.0 must rerun those tests.

Certification must be exact-artifact/exact-SHA based. Historical evidence is useful context but cannot be counted as a current PASS.

Required action:
- keep historical evidence labeled as historical;
- current certification rows must reflect only the exact v1.0 candidate.

### 4. AppLab harness is not pinned

The TrailPath workflow checks out `riccardopinato/AppLab` without a fixed ref. A later AppLab change can therefore change the certification result for the same TrailPath source/artifact.

Required action:
- pin AppLab to a commit SHA or versioned tag during CERTIFIED runs;
- record the AppLab harness SHA in the Evidence Bundle.

### 5. Current background-GPS fix is not yet certified

The planner now stops its UI-only GPS stream when the app leaves the foreground and resumes it on return. Recording/navigation keep their dedicated background-capable engines.

The source-level regression test passes, but CI #368 stopped at Network Lab before the Background Execution, Doze & Recovery Lab could validate the behavior.

Required action:
- do not mark this runtime fix as certified until the full AppLab path reaches and passes the background/Doze lab on the same candidate.

## P1 — release-critical hardening

### 6. Deleting a saved route can leave an orphan native offline map region

The route UI deletes the route and its waypoints from Drift, but does not delete the MapLibre offline region associated with that route. The offline manager already exposes a dedicated delete operation.

Impact:
- stale native map data can consume storage after the owning route no longer exists;
- database and native offline inventory can diverge.

Required action:
- make route deletion a lifecycle operation that removes/reconciles the linked offline region;
- add a regression test for route + waypoints + offline-region cleanup.

### 7. Performance has no baseline and AppLab reports severe emulator jank

The current advisory performance report has no accepted baseline and reports:
- cold startup about 1.8 s;
- PSS about 103 MB;
- RSS about 236 MB;
- 100% janky frames;
- p90 frame time about 400 ms.

This measurement is from an x86_64 emulator and is not sufficient by itself to diagnose physical-device performance, but it is too poor to ignore.

Required action:
- establish a reproducible performance baseline;
- profile the exact ARM64 candidate on a physical mid-range device;
- investigate MapLibre/platform-view rendering if the jank reproduces.

### 8. Production routing endpoint remains a reliability dependency

The README correctly states that the current public routing endpoint is suitable for development/validation and that the routing layer is provider-agnostic. For a production outdoor-navigation app, this remains an availability/rate-limit dependency.

Required action before broad rollout:
- explicitly accept and document this service risk, or
- move to a production-grade/self-hosted routing provider behind the existing contract.

### 9. Android/Play release contract must be verified from the built artifact

The Gradle config inherits Flutter's target SDK instead of pinning/recording the resolved target in certification evidence.

Required action:
- record resolved min/target/compile SDK values in CI evidence;
- verify the production AAB meets the current Play target-SDK requirement;
- verify the merged manifest contains the expected location foreground-service declaration produced by the location plugin;
- complete the corresponding Play Console foreground-service declaration before production.

## P2 — quality hardening

### 10. Automated interaction coverage is shallow

The safe interaction crawler passed but exercised only one safe candidate/control. The dedicated Maestro flow gives meaningful feature coverage, but generic interaction exploration is still narrow.

Required action:
- increase crawler-safe semantics/test IDs on key controls;
- add targeted flows for deletion, permission denial, offline-region retry and error recovery.

### 11. Accessibility evidence is partial

Planner custom controls have explicit semantics, tooltips, 48×48 targets and a regression contract. There is no equivalent end-to-end evidence yet for TalkBack, large text, contrast and all major screens.

Required action:
- add an accessibility release pass covering the complete navigation shell and critical flows.

### 12. Some UI paths expose raw exception strings

Several error surfaces use `error.toString()`. This can expose technical/provider text and bypass localization.

Required action:
- map infrastructure exceptions to localized user-facing error categories;
- keep detailed diagnostics in structured logs rather than normal UI.

### 13. Dependency major upgrade is intentionally deferred

`permission_handler` is on 12.0.3 while 13.0.2 is currently resolvable; its Android implementation also has a newer major version.

This is not a v1 RC blocker because upgrading permission behavior during certification would add churn.

Required action:
- schedule the major upgrade immediately after v1 certification with permission regression tests.

## P3 — future hardening

### 14. Local location history is sandboxed but not app-level encrypted

Routes, activities and the Back to Car point are stored locally in Drift/SQLite. Android backup/device transfer is disabled, which is positive, but the database itself is not encrypted by the app.

This is acceptable for the current local-first threat model if explicitly accepted. If stronger protection of location history becomes a product requirement, add encrypted-at-rest storage with a migration plan.

## Deletion & lifecycle audit

| Entity | Current behavior | Audit result |
| --- | --- | --- |
| Saved route | confirmation + DB delete | Needs offline-region cascade |
| Route waypoints | deleted transactionally with route | PASS |
| Completed activity | confirmation + delete | PASS |
| Recoverable recording draft | discard flow exists | PASS |
| Back to Car point | confirmation + clear | PASS |
| Native offline region | explicit delete API exists | PASS independently |
| Ambient cache | explicit clear operation exists | PASS independently |
| Route + offline region combined lifecycle | not atomic/coordinated | FAIL |

## Security & privacy audit

| Control | Result |
| --- | --- |
| Android cleartext traffic disabled | PASS |
| Platform backup disabled | PASS |
| Device-transfer extraction disabled | PASS |
| Keystore/secrets excluded from repo | PASS |
| Fail-closed store-signing mode | PASS |
| Account/ads/analytics/cloud sync absent | PASS |
| External network providers documented | PASS |
| App-level encryption of local route history | NOT IMPLEMENTED / accepted-risk decision required |
| Store-signed production artifact | NOT TESTED |

## Release decision

The current v1.0.0+28 branch should remain open and unmerged.

The next certification candidate should be created only after the P0 process defects are fixed. That candidate must rerun the whole matrix from the beginning; passing isolated historical jobs is not sufficient.

## Required certification sequence

1. Fix Network & Offline Lab root cause or reproduce/prove a harness defect without weakening the product gate.
2. Fix Evidence Bundle truthfulness.
3. Pin AppLab and record its SHA.
4. Align the release checklist to exact-candidate evidence.
5. Fix saved-route/offline-region lifecycle cleanup.
6. Run format + analyze + full tests.
7. Build exact ARM64/x86_64/AAB artifacts.
8. Run API 29 smoke.
9. Run full API 35 AppLab through every lab.
10. Run the focused no-network Maestro gate.
11. Produce a new internally consistent Evidence Bundle.
12. Install the exact ARM64 artifact on a physical device and execute production QA.
13. Configure and validate store signing.
14. Complete Play listing/screenshots and rollout review.
15. Only then merge/tag/release if every required gate is green.
