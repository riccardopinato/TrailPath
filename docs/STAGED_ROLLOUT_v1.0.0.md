# TrailPath v1.0.0 — Staged Rollout & Rollback Plan

## Rollout

1. Internal test track: exact store-signed v1.0.0+30 AAB.
2. Closed test: small tester cohort for 24–48 hours.
3. Production staged rollout: 10%.
4. Expand to 25% only if no startup crash, ANR, data-loss, navigation/offline regression or permission blocker is observed.
5. Expand to 50% after another stable observation window.
6. Expand to 100% only after stability remains within expected baseline.

## Monitor

- startup crashes and ANRs;
- recording recovery;
- route save/open/navigation;
- offline region download/restart/no-network navigation;
- battery/GPS behavior;
- permission failures;
- Play Console vitals and tester feedback.

## Pause criteria

Pause rollout immediately for:
- startup crash;
- data loss/corrupted local database;
- broken recording recovery;
- broken saved-route navigation;
- offline download or offline navigation regression;
- severe battery/GPS regression;
- privacy/permission mismatch.

## Rollback / hotfix

- Stop staged rollout first.
- Prefer a narrow hotfix over unrelated changes.
- Preserve database schema compatibility.
- Re-run targeted tests plus FULL/CERTIFIED gates.
- Never publish a rebuilt artifact under the same certification evidence without re-certifying its hash.
