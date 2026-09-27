# TrailPath v1.0.0 — Release Notes

Build: **31**

## Highlights

- Map-first planner with the permanent empty-state summary removed.
- Explicit candidate preview/confirmation for Start, Destination and intermediate waypoint.
- Map tap and mobile place search share the same selection flow.
- Confirmed user points retain exact selected coordinates while route geometry snaps to OSM.
- Compact route summary with expandable planner details.
- Coalesced/cached MapLibre annotation updates for lower platform-channel churn.
- Real OSM foot/bike routing with explicit failure handling.
- Elevation, GPX import/export and route editing.
- Track recording with pause/resume, serialized autosave and crash recovery.
- Saved-route navigation with off-route handling and arrival detection.
- Offline map preparation, restart persistence and no-network navigation validation.
- Back to Car, battery-aware GPS modes and safety checks.
- Local-first privacy posture, fail-closed store-signing mode and R8/resource shrinking.

## Automated release state

TrailPath CI **#395** passes on audited runtime source
`8cb9f2be11ddd7eddc39b73cb7a6f1932b7cbcd1`:

- format/analyze/full Flutter tests: PASS (77 tests);
- ARM64/x86_64 optimized release builds: PASS;
- AAB structure + ARM64 size gate: PASS;
- Android API 29 smoke: PASS;
- full API 35 AppLab E2E: PASS;
- Network/Offline, Persistence/Restart, Configuration/Lifecycle and Background/Doze: PASS;
- focused no-network navigation: PASS.

Exact ARM64 test candidate:
- bytes: **33,704,085**;
- SHA-256: `14e198503f1fe4568a2cf4abb69dc4ba7271a6f9985643e7c7185a582f06c38a`.

## Production state

Evidence Bundle verdict: **BLOCKED**.

Still required:
1. exact ARM64 physical-device QA, including planner fluidity and destination-selection acceptance;
2. store-signed AAB from protected signing credentials;
3. Play Store listing/screenshots review;
4. staged rollout/rollback approval.

No public v1.0.0 tag or GitHub Release should be created before the certification verdict reaches CERTIFIED.
