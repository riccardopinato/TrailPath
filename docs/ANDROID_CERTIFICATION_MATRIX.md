# TrailPath Android v1.0 certification matrix

This matrix defines the minimum device/API evidence required for v1.0.

| Target | Environment | Scope | Required |
| --- | --- | --- | --- |
| Android API 29 | Pixel 4 profile, x86_64 emulator | install, launch, process restart, crash/ANR smoke | Yes |
| Android API 35 | Pixel 7 Pro profile, google_apis x86_64 emulator | full AppLab E2E: onboarding, recording recovery, routing, navigation, offline download, restart, no-network navigation, lifecycle/background/storage labs | Yes |
| ARM64 physical Android | exact ARM64 certification-candidate APK | critical real-device flow, GPS/location, recording, navigation, offline/no-network, foreground/background | Yes before production |

The exact artifact SHA-256 is part of the Evidence Bundle. A physical-device
result is valid only for the ARM64 APK with that same SHA-256.
