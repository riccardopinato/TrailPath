# TrailPath v1.0 certification policy

TrailPath uses three validation levels:

- **FAST** — incremental development checks.
- **FULL** — complete format/analyze/test/build/AppLab checkpoint.
- **CERTIFIED** — final release evidence tied to exact artifacts.

The v1.0 certification verdict is exactly one of:

- **CERTIFIED** — automated gates pass, store signing is available and every
  required manual production gate is PASS.
- **NOT CERTIFIED** — an automated build/test/AppLab gate failed.
- **BLOCKED** — automated gates pass, but required external evidence is absent.

## Artifact identity

The Evidence Bundle records both:

1. SHA-256 of the x86_64 release APK actually exercised by AppLab on the
   API-35 Pixel 7 Pro emulator;
2. SHA-256 of the ARM64 release APK intended for physical-device/distribution
   validation.

AppLab evidence for the x86_64 artifact does not by itself certify the ARM64
artifact for production. The exact ARM64 APK must complete the physical-device
gate without being rebuilt afterwards.

## Release rule

A public production release must use the exact artifact referenced by the
CERTIFIED Evidence Bundle. A later rebuild requires a new certification cycle.
