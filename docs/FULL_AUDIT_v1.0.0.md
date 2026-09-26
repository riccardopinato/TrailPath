# TrailPath v1.0.0 — Full Audit

Audit date: 2026-09-26  
Audited runtime candidate: **v1.0.0+30**  
Audited source SHA: `e8323cab507d34fd2a09ba6978439723b3c46e29`  
Certification workflow: **TrailPath CI #376**  
AppLab harness: `8ccddca7f0f94158483df92d5fd085fe32375de9`

## Executive result

**Automated validation: PASS**  
**Production verdict: BLOCKED**

The build-30 application candidate passes the full automated certification path. Formatting, static analysis, the full Flutter test suite, ARM64/x86_64 optimized release builds, AAB structure validation, the ARM64 size budget, Android API 29 smoke, the complete API 35 AppLab gate and the focused no-network navigation flow all pass.

No code-level P0 blocker remains in the audited automated path.

Production remains BLOCKED because the exact ARM64 candidate has not yet completed physical-device QA, Play Store signing is not configured, and final Play listing/screenshots plus staged-rollout approval are still not evidenced. No public v1.0.0 tag/release should be created before those gates are complete.

## Exact automated evidence

| Area | Result | Evidence |
| --- | --- | --- |
| Formatting | PASS | CI #376 |
| flutter analyze | PASS | CI #376 |
| Full Flutter tests | PASS | CI #376 |
| ARM64 release APK | PASS | 33,638,317 bytes |
| ARM64 SHA-256 | PASS | `9bb600e7dc81deabf2b9f1182094da0ece9ed60ad90d5dca0d42ec7217d34e84` |
| x86_64 release runtime | PASS | 35,516,030 bytes |
| Release AAB structure | PASS | CI #376 |
| ARM64 size budget | PASS | below 40 MiB |
| Android API 29 smoke | PASS | install / launch / restart |
| API 35 AppLab | PASS | complete gate |
| Network & Offline Lab | PASS | zero errors/warnings |
| Persistence & Restart Lab | PASS | zero errors/warnings |
| Configuration & Lifecycle | PASS | zero errors/warnings |
| Background / Doze recovery | PASS | zero errors/warnings |
| Focused no-network navigation | PASS | Maestro gate |
| Smart Visual QA | PASS | zero errors/warnings |
| Safe Interaction Crawler | PASS | one safe action exercised |
| Resource Pressure Lab | WARN | trim-memory request rejected by Android; no app error |
| Storage & Data Integrity Lab | WARN | release APK private storage not inspectable with run-as |
| Visual Regression | NO_BASELINE | first passing checkpoint available |
| Performance Lab | WARN | no accepted baseline; emulator advisory metrics |
| Store-signed AAB | NOT TESTED | secrets absent |
| Exact ARM64 physical QA | NOT TESTED | external gate |
| Play assets/review | NOT TESTED | external gate |
| Staged rollout approval | NOT TESTED | external gate |

## Architecture and implementation

The architecture is coherent for the current scope: app/core/features/infrastructure separation, Riverpod dependency injection, explicit service contracts, Drift persistence and provider-isolated map/routing/location/navigation implementations. The design keeps routing, elevation, location, offline maps and feedback replaceable without coupling the UI to one infrastructure provider.

The local lifecycle is materially stronger than the earlier release candidates:
- recoverable recording drafts are persisted;
- route/offline-region deletion is coordinated;
- offline readiness is reconciled against native MapLibre state;
- interrupted downloads can recover;
- planner-only GPS tracking stops outside the foreground;
- recording/navigation retain their dedicated background-capable engines;
- API 29 and API 35 validation are separated;
- the AppLab harness is pinned to an exact SHA;
- artifact identity is recorded by SHA-256.

## Security and privacy

| Control | Result |
| --- | --- |
| Cleartext HTTP disabled | PASS |
| Android backup disabled | PASS |
| Device-transfer extraction disabled | PASS |
| Signing secrets excluded from source | PASS |
| Store mode fails closed when signing is required | PASS |
| Account/ads/analytics/cloud sync absent | PASS |
| External network providers documented | PASS |
| App-level encryption of local route/activity history | NOT IMPLEMENTED |
| Store-signed production artifact | NOT TESTED |

The lack of app-level database encryption is not a current functional blocker because the documented threat model is local-first with platform backup disabled. It remains an explicit product/security decision if stronger at-rest protection is desired later.

## Deletion and data lifecycle

| Entity | Result |
| --- | --- |
| Saved route | PASS — confirmation + coordinated offline cleanup |
| Route waypoints | PASS — removed with route |
| Completed activity | PASS — explicit delete |
| Recoverable recording draft | PASS — discard flow |
| Back to Car point | PASS — explicit clear |
| Native offline region | PASS — explicit delete and route cascade |
| Ambient map cache | PASS — explicit clear |

No known orphan-data P0 remains from the previously identified route/offline lifecycle defect.

## P0 — production blockers

There are no remaining code-level P0 blockers in the automated certification path.

The release is still blocked by four external gates:
1. install and test the exact ARM64 SHA-256 candidate on a physical device;
2. configure GitHub/Play Store signing and build/verify the store-signed AAB;
3. capture and approve Play Store listing/screenshots from the exact accepted build;
4. complete staged-rollout and rollback approval.

## P1 — release-quality hardening

### 1. Physical performance baseline

AppLab performance remains advisory and has no accepted baseline. On the API 35 x86_64 emulator it reported:
- cold startup: 3142 ms;
- PSS: 103,849 KB;
- RSS: 238,664 KB;
- janky frames: 100%;
- p90 frame time: 850 ms.

These numbers are not sufficient to diagnose ARM64 physical-device performance, but they are too poor to ignore. The exact ARM64 APK should be profiled on a representative mid-range Android device before broad rollout, with special attention to MapLibre/platform-view startup and first-map interaction.

### 2. Visual regression baseline

Smart Visual QA passes, but Visual Regression is still NO_BASELINE. Promote the current full-PASS visual checkpoint only after confirming it represents the intended UI. Future release gates can then detect visual drift.

### 3. Full-app accessibility

Planner-specific semantics, tooltips and minimum touch-target contracts exist, but there is no recorded end-to-end TalkBack, large-text and contrast pass across all critical screens. Perform this before broad production rollout or immediately after the initial controlled release.

### 4. Generic interaction coverage is narrow

The Safe Interaction Crawler found and exercised only one safe candidate: place/trail search. Dedicated Maestro flows provide much stronger domain coverage, so this is not a release blocker, but generic exploratory coverage should be broadened for destructive actions, permission denial, retry/error states and offline management.

### 5. Android release contract evidence

The Gradle project resolves compile/min/target SDK values through Flutter. Certification should record the resolved values and the merged foreground-location service contract from the built release artifact so Play Console declarations can be checked against exact evidence rather than source assumptions.

### 6. Routing-provider production dependency

The current public OSM routing endpoint remains an availability/rate-limit dependency. The provider abstraction is already correct; before a large user rollout, either explicitly accept/document this dependency or place a production-grade/self-hosted provider behind the existing RoutingEngine contract.

## P2 — post-v1 hardening

- Replace remaining raw infrastructure exception strings shown in UI with localized user-facing categories while preserving details in structured logs.
- Schedule the deferred `permission_handler` major upgrade after v1 certification and rerun permission/background regression tests.
- Decide whether local route/activity history requires app-level encryption at rest.
- Convert the first accepted passing screenshots/performance measurements into explicit regression baselines.
- The Storage Lab warning is an observability limitation of a non-debuggable release APK (`run-as` unavailable), not proof of corruption. If deeper automated release-storage validation is required, add an instrumentation/self-check path rather than weakening the release build.

## Documentation audit

The build-30 code/CI state is stronger than some release documents that still referenced build 28/29. This audit aligns:
- full audit status to build 30;
- release checklist versioning to 1.0.0+30;
- release notes to build 30;
- staged-rollout target to the exact v1.0.0+30 store AAB;
- README and roadmap with the current audit outcome.

These are documentation-only changes. Because TrailPath certification intentionally binds evidence to an exact source SHA, committing this audit documentation triggers a fresh CI/evidence cycle even though no runtime source is changed.

## Release decision

**Do not tag or publish v1.0.0 yet.**

The application is technically ready for the user's physical ARM64 test phase. The next production decision should be based on the exact post-audit certification artifact plus physical QA and store-signing evidence.

The public v1.0.0 tag/release becomes eligible only when the Evidence Bundle verdict reaches **CERTIFIED**.


## Post-audit physical UX feedback — release hold

After the build-30 automated PASS, physical-device testing identified three pre-release UX issues that are not represented by emulator crash/ANR gates:

1. **Planner fluidity is insufficient** during normal map interaction and planning.
2. **Destination selection is ambiguous/inaccurate in practice.** The current planner mutates the route immediately on map tap, while search uses a separate focus-marker flow; there is no shared preview/confirm state.
3. **The full PlannerCard is permanently visible**, including when the route is empty, reducing the map viewport and making the home/planner screen feel constrained.

These are now **P1 pre-release blockers** even though they are not P0 crash/data-integrity defects. The build-30 automated evidence remains historically valid for its exact SHA, but v1.0 must not ship from that artifact. The next runtime candidate must implement the map-first UX/performance roadmap, then rerun the full certification sequence.

Reference direction is documented in `docs/REFERENCE_APPS_UX_BENCHMARK_2026.md`.
