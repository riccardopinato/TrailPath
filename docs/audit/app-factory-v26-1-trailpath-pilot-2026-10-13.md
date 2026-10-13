# App Factory v26.1 TrailPath Pilot — 2026-10-13

## Baselines

- App Factory Core: `23c5b0f6b5f02a93e03bb36106f12575a58129d3`
  - Master v26.1 FULL
  - Golden Index v12
  - Agent Governance v1 COPY-READY PROCESS
  - Code Hygiene v0.2 DRAFT / PROCESS CANDIDATE
- TrailPath post-v1 baseline:
  `feature/v1.1-v1.5 @ 44b95f8cb398cb141938452254c96a20d55b6eea`
- Verified repository `main` at pilot time:
  `3f44ab37c0881e4315033797c451cec723e23cd2` / `0.9.15+27`.
  The pilot intentionally targets the separate post-v1 cumulative lineage above.

## Historical Trace Mode finding

The field-reported failure text "Impossibile convertire il gesto in un percorso"
exists on the old planner path, but the current post-v1 implementation already
contains the substantive replacement:

- map-local pointer coordinate conversion;
- Android logical-pixel -> native physical-pixel projection scaling before
  MapLibre `toLatLng`;
- higher trace sampling budget;
- zoom-aware gesture tolerance;
- Valhalla Smart Trace map matching for Trail/Road modes;
- routing fallback with corridor validation;
- Free mode intentionally retains the free-form trace path.

Therefore this pilot does not reapply an obsolete fix from `main`.

## Current routing finding

The post-v1 routing provider setup used nested `FallbackRoutingEngine`
instances to express OSM -> Valhalla -> local-unsnapped behavior.

The nested wrapper works, but has two concrete drawbacks:

1. provider ordering/failover is encoded indirectly through nested wrappers;
2. if every snapped provider fails, the outer wrapper logs the secondary
   failure but rethrows the first provider error, losing the final diagnostic.

This is a real code-hygiene/diagnostic defect in a subsystem that now has more
than one snapped provider.

## Replacement

Replace `FallbackRoutingEngine` with `RoutingProviderChain`:

- ordered snapped providers are explicit;
- `snapToNetwork=false` immediately uses the local unsnapped fallback;
- snapped requests try providers in order;
- unsnapped results are rejected for snapped requests;
- the final provider failure is preserved if all providers fail;
- production keeps only the dedicated Valhalla provider;
- development/internal keeps OSM first, Valhalla second;
- straight-line behavior remains explicit-only.

The old wrapper and old fallback-specific regression file are removed.

## Code Hygiene evidence

Feature replacement:
- superseded `FallbackRoutingEngine` removed;
- nested wrapper configuration removed;
- replacement provider chain is the single routing failover path.

Bug fix:
- final failover error is no longer discarded;
- deterministic tests prove provider order, successful failover, final-error
  propagation, rejection of unsnapped provider output and no-network behavior
  for `snapToNetwork=false`.

KEEP:
- `StraightLineRoutingEngine`: intentional explicit unsnapped route behavior;
- Free Smart Trace path: intentional product mode;
- Valhalla routing/map-matching engines: active provider implementations.

OUT OF SCOPE:
- physical ARM64 QA;
- Play/provider console configuration;
- unrelated 111k-line planner decomposition;
- chart/elevation redesign;
- stale historical branches/PR deletion.

## Validation target

Final-state validation must run after replacement/cleanup:

- format gate;
- Flutter analyze;
- Flutter tests including provider-chain regressions;
- Web parity build;
- release Android gates;
- routing provider smoke/AppLab gates triggered by the repository CI.

No previous v1.5.21 certification claim is automatically inherited by the
v1.5.22 source change.

## Pre-CI verdict

**IMPLEMENTED — EXACT-HEAD VALIDATION PENDING**


## AppLab E2E stability note

On exact head `2e85677a77fda4b0e6e9f7a2f00c05b44cedb33d`, the comprehensive
AppLab Android E2E lane produced two different non-deterministic failures while
all focused/runtime/build gates remained green:

1. attempt 1 reached the full journey and later reported a Configuration &
   Lifecycle Stress Lab ANR signal that was not retained in the final target
   logcat;
2. attempt 2 failed much earlier because Maestro reported the Record bottom-nav
   tap as completed while the screenshot/UI remained on the healthy Plan screen.

The previous v1.5.21 exact source baseline passed the same AppLab E2E lane in
TrailPath CI #841. The E2E flow therefore keeps all product assertions but adds
a bounded idempotent retry only when the previous Plan state is still visible
after the Record-tab tap. This does not convert a missing Record screen into a
PASS: `Start recording` / `Recovered recording` remain mandatory.
