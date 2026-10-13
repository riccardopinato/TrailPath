# AGENTS.md

## Authority

TrailPath resolves App Factory rules deterministically from:
`riccardopinato/App-Factory-Core/CURRENT.yaml`.

For Factory-dependent development, audit, roadmap, hardening or release work,
resolve once per session:

1. `CURRENT.yaml`
2. `master.path`
3. `golden_index.path`
4. `golden/GOLDEN_REGISTRY.yaml`
5. only the Golden documents relevant to the task

Pin that App-Factory-Core commit SHA as the Factory baseline. Chat memory and
historical attachments never override the resolver.

For TrailPath product work, authority is:

1. current TrailPath Product Truth / `docs/ROADMAP.md`;
2. resolved App Factory Master + relevant Golden;
3. current branch implementation and executable tests;
4. verified internal donors;
5. compatible OSS/current provider documentation;
6. new code.

## Branch lineage

The post-v1 cumulative product line is `feature/v1.1-v1.5` and descendants.
Do not assume repository `main` is the newest product implementation when
working on v1.1+ features.

Before mutation, identify the intended lineage and exact base SHA.
Do not merge stale/superseded feature branches into the current candidate merely
because they contain older versions of a requested feature.

## Product invariants

- Flutter/Dart remains the app stack.
- Local-first/offline-first core behavior is mandatory.
- Account/cloud/Pro/provider services remain optional boundaries and fail safe
  when configuration is absent.
- Never fabricate provider availability, routing success, store delivery,
  offline readiness or certification evidence.
- A snapped route must be genuinely provider-snapped or fail explicitly.
- A straight-line route is allowed only when explicitly requested as unsnapped
  behavior.
- Preserve confirmed user-selected waypoint coordinates while routing geometry
  may snap to the network.
- Physical-device/store/provider gates remain distinct from CI PASS.

## Code hygiene

For every substantial implementation, bug fix, refactor, provider change or
dependency change, inspect the affected subsystem for superseded paths.

Adding a replacement without evaluating removal of the superseded implementation
is incomplete work.

Check when relevant:
- dead/unreachable code;
- duplicate routing/provider/coordinator paths;
- superseded workarounds;
- unused dependencies/assets/resources;
- stale feature flags/TODOs;
- touched deprecated APIs.

Cleanup is bounded to the affected subsystem. Do not use it to justify unrelated
architecture rewrites.

If an old path is replaced, remove it when safe rather than leaving parallel
implementations active.

## Routing / Smart Trace

- Keep routing and map matching provider-agnostic.
- Development/internal routing may use community providers only under the
  documented provider policy.
- Production/store readiness must honor the dedicated provider boundary.
- Smart Trace Trail/Road modes use map matching; Free mode intentionally keeps
  the free-form trace path and is not dead code.
- Never silently replace a routing/map-matching failure with fake snapped
  geometry.
- Provider failover must be covered by deterministic tests.

## Validation

Use the App Factory validation ladder.

For substantial TrailPath changes, final-state evidence normally includes:
- `dart format` / repository formatting gate;
- `flutter analyze`;
- `flutter test`;
- relevant Web build/parity gate;
- affected Android release/runtime gates;
- AppLab/device evidence when the capability requires it.

Validation must run after bounded cleanup.

Build PASS != runtime PASS.
Web Preview != native certification.
Automated PASS != physical ARM64/store/provider certification.

## Git / PR

- Keep the selected baseline stable.
- Use a dedicated branch/PR for substantial work.
- Do not overwrite unrelated user-owned changes.
- Do not merge a PR unless explicitly authorized by the user.
- Preserve exact source/artifact SHA evidence when release artifacts are
  involved.
- Do not revive a superseded branch when its behavior already exists in a newer
  lineage; port only the still-valid delta.

## Completion

Before DONE:
- requested behavior exists;
- root cause is addressed;
- regression coverage exists when practical;
- superseded code was evaluated and removed when safe;
- final validation ran on the cleaned tree;
- docs/roadmap reflect actual state;
- external/physical blockers remain explicitly BLOCKED/NOT VERIFIED.
