# TrailPath v1.0.0 — Staged Rollout & Rollback Plan

## Rollout

1. Internal test track: exact store-signed **v1.0.0+31** AAB derived from the accepted runtime source.
2. Closed test: small tester cohort for 24–48 hours.
3. Production staged rollout: 10%.
4. Expand to 25% only if no startup crash, ANR, data loss, planner-selection regression, severe map jank, navigation/offline regression or permission blocker is observed.
5. Expand to 50% after another stable observation window.
6. Expand to 100% only after stability remains within the accepted baseline.

## Pre-rollout physical acceptance

Before internal/closed production promotion, validate the exact ARM64 APK/AAB lineage for:

- map startup, pan/zoom and destination preview responsiveness;
- exact destination/start pin placement and bottom-sheet visibility;
- waypoint drag/edit behavior;
- recording start/pause/recovery/finish;
- saved-route navigation and off-route recovery;
- offline download, restart and no-network route use;
- foreground/background transitions without crash/ANR.

## Monitor

- startup crashes and ANRs;
- planner map jank and destination-selection feedback;
- recording recovery/finalization;
- route save/open/navigation;
- offline region download/restart/no-network navigation;
- battery/GPS behavior;
- permission failures;
- Play Console vitals and tester feedback.

## Pause criteria

Pause rollout immediately for:
- startup crash;
- data loss/corrupted local database;
- broken recording recovery/finalization;
- broken saved-route navigation;
- destination/waypoint placement materially different from the selected point;
- reproducible severe map-interaction jank on supported physical devices;
- offline download or offline navigation regression;
- severe battery/GPS regression;
- privacy/permission mismatch.

## Rollback / hotfix

- Stop staged rollout first.
- Prefer a narrow hotfix over unrelated changes.
- Preserve database schema compatibility.
- Re-run targeted tests plus FULL/CERTIFIED gates.
- Never publish a rebuilt artifact under the same certification evidence without re-certifying its hash.
