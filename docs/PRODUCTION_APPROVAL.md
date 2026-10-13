# TrailPath v1.0.0 production approval

This file records only release evidence that cannot be produced by the normal
GitHub/AppLab automation. Do not mark an item PASS without the corresponding
real-world evidence.

- Physical ARM64 device QA: NOT TESTED
- Play Store listing/screenshots review: NOT TESTED
- Staged rollout / rollback review: NOT TESTED

## Physical ARM64 QA evidence

Current automated candidate: **v1.5.21+58**, TrailPath CI **#835**.
Exact ARM64 APK SHA-256:
`55c0446381371e545b738117c640879e44ca4680cb36582fba4cee873f89e89d`
(35,820,865 bytes).

The physical test must use this exact ARM64 APK whose SHA-256 appears in the
current Evidence Bundle. Rebuilding the APK invalidates this evidence.

Minimum critical flow:

1. clean install / first-run onboarding;
2. location permission and live map;
3. create and save a routed path;
4. start, pause, recover and finish a recording;
5. start saved-route navigation;
6. download the route offline;
7. close/reopen the app and confirm offline readiness;
8. disable network and open the downloaded route/navigation;
9. verify no crash/ANR during foreground/background transitions.

Record device model, Android/API version, APK SHA-256 and result here before
changing `Physical ARM64 device QA` to `PASS`.

## Store evidence

The production Play Store gate additionally requires the store-signed AAB
generated from repository secrets, final listing/screenshots review and an
explicit staged-rollout/rollback plan.
