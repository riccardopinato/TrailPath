# TrailPath v1.0.0 — Full Deep Audit

Audit date: **2026-09-27**  
Audited runtime candidate: **v1.0.0+31**  
Audited runtime source SHA: `8cb9f2be11ddd7eddc39b73cb7a6f1932b7cbcd1`  
Certification workflow: **TrailPath CI #395** / run `36278249499`  
AppLab harness: `16271b3ffa34982a0f04fd118565047e7c09e743`

## Executive result

**Automated validation: PASS**  
**Production verdict: BLOCKED**  
**Code-level P0 blockers found: 0**

Build 31 passes the complete automated release path currently defined by the repository: formatting, static analysis, 77 Flutter tests, ARM64 and x86_64 optimized release builds, AAB structure validation, ARM64 size budget, Android API 29 smoke, complete API 35 AppLab E2E and the focused no-network flow.

Production is not CERTIFIED because the Evidence Bundle truthfully reports missing external gates: store-signing credentials, exact ARM64 physical-device QA, Play Store listing/screenshots review and staged-rollout/rollback approval.

The planner UX remediation is materially better than build 30: the map is primary, destination selection is explicit, selected coordinates no longer jump to provider-snapped waypoints, and MapLibre updates are less redundant. The remaining risk is now mostly physical-device UX/performance validation and release-quality debt rather than known automated crash/data-loss defects.

## Exact build-31 evidence

| Area | Result | Evidence |
| --- | --- | --- |
| Dart format | PASS | CI #395, 72 files checked / 0 changed |
| flutter analyze | PASS | No issues found |
| Flutter tests | PASS | **77 tests passed** |
| ARM64 release APK | PASS | **33,704,085 bytes** |
| ARM64 APK SHA-256 | PASS | `14e198503f1fe4568a2cf4abb69dc4ba7271a6f9985643e7c7185a582f06c38a` |
| x86_64 AppLab APK | PASS | 35,516,258 bytes |
| x86_64 SHA-256 | PASS | `1f9b70cc4b59842080daf9fe46794e7e999cf6bc16b1af81a40960eb1419a5e7` |
| AAB structure gate | PASS | CI #395 |
| ARM64 size gate | PASS | 33.7 MB < 40 MiB |
| Android API 29 smoke | PASS | install / launch / restart |
| API 35 AppLab | PASS | complete release E2E |
| Maestro | PASS | build-31 planner flow included |
| Network & Offline | PASS | errors 0 / warnings 0 |
| Persistence & Restart | PASS | 2 cycles, errors 0 / warnings 0 |
| Configuration & Lifecycle | PASS | 6 stages, errors 0 / warnings 0 |
| Background / Doze recovery | PASS | errors 0 / warnings 0 |
| Smart Visual QA | PASS | errors 0 / warnings 0 |
| Multi-screen Visual Journey | PASS | AppLab |
| Safe Interaction Crawler | PASS but narrow | 1 candidate / 1 action |
| Resource Pressure | WARN | Android rejected one trim-memory request; app errors 0 |
| Storage & Data Integrity | WARN | release APK private storage not inspectable with `run-as`; app errors 0 |
| Upgrade & Migration Lab | NO_BASELINE | previous APK unavailable |
| Visual Regression | NO_BASELINE | no accepted prior visual checkpoint |
| Performance Lab | WARN / NO_BASELINE | emulator-only advisory metrics |
| Store-signed AAB | NOT TESTED | signing secrets absent |
| Exact ARM64 physical QA | NOT TESTED | external gate |
| Play listing/screenshots | NOT TESTED | external gate |
| Staged rollout/rollback approval | NOT TESTED | external gate |

## Performance audit

AppLab API 35 x86_64 emulator metrics for build 31:

- cold startup: **2,138 ms**;
- PSS: **100,370 KB**;
- RSS: **228,908 KB**;
- janky frames: **100% (3/3 sampled frames)**;
- p90 frame: **900 ms**;
- Performance Lab: **WARN / NO_BASELINE**.

Compared with the previous build-30 emulator checkpoint, cold startup and memory are lower, but the frame sample is too small and emulator/platform-view timing is too noisy to use as proof of real ARM64 smoothness. The user's physical feedback about map fluidity therefore remains the authoritative unresolved performance signal.

**Release implication:** physical ARM64 pan/zoom, destination preview, route edit and waypoint-drag responsiveness are P1 acceptance criteria.

## Planner UX and route-selection audit

### Improvements verified

- Empty planner no longer renders the full `PlannerCard`; the map keeps most of the screen.
- One confirmed point shows a compact “choose destination” prompt.
- A valid route shows a compact distance/time/ascent bar; full detail is moved to a draggable sheet.
- Map tap and mobile place search enter one temporary candidate state.
- Start/Destination/Add waypoint require explicit confirmation before route mutation.
- Confirmed user-selected points remain at the selected coordinates; provider snapped coordinates are used only to split/interpret route geometry.
- Annotation updates are coalesced and unchanged route/waypoint/midpoint visuals are not rewritten unnecessarily.

### Remaining P1 UX risks

1. **Physical camera-padding/occlusion validation.** Search focus currently centers the selected coordinate, but does not explicitly compensate camera padding for the candidate bottom sheet. A point near the bottom edge can therefore still require physical validation for visibility.
2. **Compact-row resilience.** The route summary places three metrics plus actions in one Row. Small screens and large text are not currently represented by a dedicated runtime gate.
3. **Toolbar density.** The large permanent summary is gone, but TrailPath chip + Trace + Undo + Redo + Recenter + Search still consume non-trivial top-map space.
4. **Long-press mutation remains a separate route-edit shortcut.** It is guarded by route proximity, but does not use the candidate confirmation flow.

## Android/Web parity audit — P1 regression

The planner **domain core** remains shared: Android/Web use the same `RoutePlannerController`, routing/elevation/search providers and persistence-independent route logic.

The **Web Preview presentation is no longer UX-parity with build 31**:

- Web map click still calls immediate `addPoint`;
- Web search still focuses a separate search marker and uses a separate “add result as waypoint” path;
- Web MapLibre annotation sync still rewrites existing line/circle annotations sequentially rather than using the mobile visual-key cache/coalescing strategy;
- Web preview still contains hardcoded/localized-inconsistently user-facing error strings.

This does not invalidate the Android release artifact, but it violates the project's stated “Full Web/Core Parity” quality goal. Restore parity before calling the project fully converged.

## Routing audit

Strengths:

- Foot/bike routing is behind `RoutingEngine`.
- Requests are chunked above 20 waypoints with overlapping seams.
- HTTP 408/425/429/5xx, timeouts and client failures use bounded retry/backoff.
- `Retry-After` is honored.
- Incomplete snapped-waypoint responses fail explicitly.
- A real snapped route never silently degrades to a fake straight line; straight-line routing is used only when explicitly requested.

Risks:

1. **Public routing endpoint dependency — P1 before scale.** `routing.openstreetmap.de` is an external availability/rate-limit dependency. The abstraction is correct, but production policy must explicitly accept it or replace/self-host it.
2. **Partial-reroute ETA consistency — P2.** Full provider routes use provider duration. After a cached partial reroute, merged geometry distance is recomputed and ETA falls back to a fixed speed-per-profile estimator. ETA semantics can therefore change after editing the same route.
3. **Imported GPX profile change semantics — review.** Imported GPX stores endpoints as planner points; changing activity profile triggers a provider reroute of those points, replacing imported geometry. This may be acceptable, but should be treated as deliberate UX rather than accidental behavior.

## Search and elevation audit

### Nominatim search

- queries shorter than two characters are rejected;
- uncached requests are serialized;
- minimum one-second request gap is enforced;
- in-memory cache is bounded;
- transient retries and `Retry-After` behavior are present;
- language preference is forwarded.

Search is user-triggered rather than keystroke autocomplete, which is appropriate for rate control.

### Elevation

- Open-Meteo requests are capped by resampling to at most 100 points;
- transient retry/backoff exists;
- failures degrade to “elevation unavailable” instead of invalidating the route;
- DEM noise filtering is covered by tests.

## Recording audit

Strengths:

- runtime permissions are requested before creating a recoverable database draft;
- autosave is serialized and bounded by point/time thresholds;
- pause writes an awaited checkpoint before the UI exposes paused state;
- interrupted drafts restore paused after restart;
- stale stream/session work is guarded;
- implausible GPS jumps and poor accuracy are filtered;
- recording continues through Android foreground notification configuration.

### Recording finalization error path — P2

`finish()` stops the platform recorder before completing the Drift row. If final database completion fails, the controller returns false with an error after the recorder has stopped. The presentation currently interprets false as “activity too short” and clears the rendered track. The incomplete draft may remain recoverable after restart, but retry/recovery is not explicit in-session.

Required fix: distinguish “too short” from “save failed”, preserve/recover the stopped snapshot, and offer retry/discard without requiring an app restart.

## Navigation audit

- saved-route geometry is used locally;
- route projection/progress and remaining distance are local;
- off-route/back-on-route use hysteresis;
- arrival detection is explicit;
- route layer is static and GPS/off-route overlays update incrementally;
- battery-mode changes are applied live;
- TTS and haptic failures are isolated from GPS navigation;
- background/Doze AppLab gate passes.

TrailPath is route-following navigation with status/TTS alerts, not a full maneuver-by-maneuver navigation engine. Current store wording (“navigate with live progress”) is consistent with that scope.

## Offline audit

Strengths:

- offline readiness is reconciled against native MapLibre regions after restart;
- interrupted/incomplete region state can be restarted;
- saved-route deletion removes its associated native offline region before deleting route rows;
- ambient cache clear is distinct from saved offline regions;
- focused no-network navigation passes AppLab.

Debt:

- download cancellation is not part of the `OfflineMapManager` contract; a long download cannot be explicitly cancelled from the domain/UI;
- incomplete download restart deletes/restarts the native region rather than resuming byte-for-byte;
- no user-facing estimated download size is shown before start.

These are P2 UX/resource-management items, not current data-integrity blockers.

## Persistence and data lifecycle audit

Drift schema v3 stores routes, waypoints, activities, return point and settings.

Verified design points:

- route + waypoint creation/deletion use transactions;
- v1/v2 → v3 migrations have dedicated tests;
- recorded activity drafts recover after restart;
- route geometry and waypoint coordinates are stored independently;
- Back to Car can be cleared explicitly;
- completed activities have explicit delete;
- native offline route data participates in route deletion lifecycle.

No known automated orphan-data P0 remains.

## Security and privacy audit

| Control | Result |
| --- | --- |
| Cleartext HTTP | PASS — disabled |
| Android backup | PASS — disabled |
| Device-transfer extraction | PASS — excluded |
| Signing secrets committed | PASS — none required in source |
| Store mode fail-closed | PASS |
| Accounts / ads / analytics / cloud sync | absent |
| External providers documented | PASS |
| Explicit user sharing for GPX/location | PASS |
| Local database app-level encryption | NOT IMPLEMENTED |
| Store-signed production AAB | NOT TESTED |

The plaintext Drift database lives in Android private app storage and platform backup/device-transfer paths are disabled. This is acceptable for the current documented local-first threat model, but route/activity/parking coordinates remain sensitive if the device/app sandbox is compromised. App-level encryption is therefore a P2 product/security decision, not a hidden guarantee.

## Permissions and Android release contract

Declared permissions are limited to Internet, coarse/fine location, foreground service/location, wake lock and notifications.

The source contract is coherent with background recording/navigation, and API 29/API 35 runtime gates pass. However, the Evidence Bundle does **not** currently record resolved concrete compile/min/target SDK values or the merged release manifest/foreground-service contract. That evidence should be captured before Play publication so store declarations are tied to the exact artifact.

## Accessibility audit

Positive:

- planner custom map buttons have Semantics, Tooltips and 48×48 contract checks;
- Material controls supply baseline semantics;
- AppLab Smart Visual QA passes.

Missing:

- no recorded end-to-end TalkBack pass;
- no large-font runtime checkpoint;
- no dedicated small-screen checkpoint;
- map-only waypoint manipulation lacks a fully equivalent non-map editing surface;
- compact summary/candidate controls need text-scaling validation.

This is P1 release-quality work if broad accessibility is part of v1 acceptance; otherwise it must remain explicitly documented post-release debt.

## Localization audit

Core user-facing strings are available in IT/EN/ES/FR/PT, including the build-31 candidate flow and TTS status messages.

Remaining hardcoded/inconsistent surfaces include:

- Android foreground-service notification strings in recording/navigation;
- several raw `error.toString()` messages;
- Web Preview error copy;
- OSM search attribution/support copy;
- duplicated semantic version display source.

These are P2/P3 rather than functional blockers.

## Dependency and build audit

CI dependency audit reports one deliberate major-version debt:

- `permission_handler` 12.0.3 → 13.0.2 available;
- `permission_handler_android` 13.0.1 → 14.1.0 available.

The upgrade is resolvable but should not be mixed into the RC without permission/background regression. CI also reports plugin/toolchain warnings (for example Flutter TTS/Kotlin plugin and a deprecated geolocator Android API), but current analyze/build/AppLab gates pass.

Release uses R8 + resource shrinking. ARM64 APK is 33.7 MB and passes the 40 MiB project budget.

## Test architecture audit

Strong coverage exists for:

- domain geometry/sampling;
- routing retries/snap validation/failures;
- elevation;
- search;
- recording recovery;
- navigation transitions;
- offline reconciliation/deletion/restart;
- Drift migrations;
- onboarding;
- API 29 release smoke;
- API 35 E2E and no-network behavior.

Weaknesses:

1. several “architecture contract” tests inspect source strings rather than user behavior;
2. build-31 candidate-selection semantics are covered by a source contract plus Maestro happy path, but not a focused Flutter widget interaction suite;
3. Safe Interaction Crawler finds only one generic safe action;
4. Visual Regression and Upgrade/Migration AppLab lack baselines.

## Documentation audit

Before this deep audit, several release documents still described build 30 or build 31 as “awaiting re-certification”, despite CI #395 already being green. Documentation is being realigned to:

- build **1.0.0+31**;
- CI **#395** automated PASS;
- exact build-31 ARM64 identity;
- current AppLab harness SHA;
- current BLOCKED external production gates;
- newly identified P1/P2/P3 debt.

## Priority summary

### P0
No code-level P0 found in the current automated candidate.

### Hard external release blockers
1. exact ARM64 physical-device QA;
2. store signing + verified store AAB;
3. Play Store listing/screenshots review;
4. staged rollout/rollback approval.

### P1 release-quality
1. real ARM64 map/selection/frame-time acceptance;
2. Web Preview UX/performance parity with build 31;
3. full-app accessibility + small-screen/large-text validation;
4. resolved SDK + merged foreground-service evidence;
5. production routing-provider reliability decision;
6. accepted visual/performance baseline after physical UI approval.

### P2
1. partial-reroute ETA semantic consistency;
2. recording finish/save failure recovery;
3. localized error taxonomy and foreground notifications;
4. offline download cancellation/size UX;
5. encryption-at-rest decision;
6. permission_handler major upgrade;
7. stronger behavioral widget tests;
8. upgrade/migration baseline;
9. version-source deduplication.

### P3
Toolbar/attribution and other polish after physical QA.

## Audit scorecard

These scores are qualitative engineering assessments, not automated measurements.

| Area | Score |
| --- | ---: |
| Architecture & separation | 9.2 / 10 |
| Planner/routing correctness | 9.1 / 10 |
| Recording/data recovery | 9.2 / 10 |
| Navigation/offline reliability | 9.3 / 10 |
| Security/privacy posture | 8.8 / 10 |
| Accessibility | 7.4 / 10 |
| Performance evidence | 7.3 / 10 |
| Testing/CI/certification | 9.6 / 10 |
| Release readiness | 8.8 / 10 |
| **Overall** | **8.9 / 10** |

## Release decision

**Do not tag/publish v1.0.0 yet.**

The build-31 Android runtime has a strong automated PASS and is suitable for the exact physical ARM64 acceptance phase. Production eligibility begins only after the external gates are complete and the Evidence Bundle reaches **CERTIFIED**.

Because this audit updates repository documentation, the documentation commit itself changes the branch source SHA. Under TrailPath's exact-SHA certification policy, that documentation-only commit must trigger a fresh CI/evidence cycle even though no runtime Dart/Android source is changed.
