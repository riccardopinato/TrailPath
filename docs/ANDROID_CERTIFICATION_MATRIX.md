# TrailPath Android v1.0 certification matrix

This matrix defines the minimum device/API evidence required for v1.0.

| Target | Environment | Scope | Required |
| --- | --- | --- | --- |
| Android API 29 | Pixel 4 profile, x86_64 emulator | install, launch, process restart, crash/ANR smoke | Yes |
| Android API 35 | Pixel 7 Pro profile, google_apis x86_64 emulator | full AppLab E2E: onboarding, recording recovery, routing, navigation, offline download, restart, no-network navigation, lifecycle/background/storage labs | Yes |
| ARM64 physical Android | exact ARM64 certification-candidate APK | critical real-device flow, GPS/location, recording, navigation, offline/no-network, foreground/background | Yes before production |

The exact artifact SHA-256 is part of the Evidence Bundle. A physical-device
result is valid only for the ARM64 APK with that same SHA-256.


## Current automated evidence

- Candidate: **v1.5.21+58**
- Full automated matrix: **TrailPath CI #835 — PASS**
- Pinned AppLab harness: `d6f2df29099e4744e750480321b15bc04b045d61`
- AppLab-tested x86_64 SHA-256: `ca46fb550780f623e4e8b7336bd4a6f8f3fd50b410ed0ae468a5d729a95ef051`
- Physical candidate ARM64 SHA-256: `55c0446381371e545b738117c640879e44ca4680cb36582fba4cee873f89e89d`
- Automated validation: **PASS**
- Production status: **BLOCKED** only by store/provider configuration and physical/release evidence.
