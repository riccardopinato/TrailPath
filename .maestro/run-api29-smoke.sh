#!/usr/bin/env bash
set -euo pipefail

APK="apk/app-x86_64-release.apk"
PACKAGE="com.riccardopinato.trail_path"
REPORT_DIR="api29-report"

mkdir -p "$REPORT_DIR"
adb install -r "$APK"
adb logcat -c

adb shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1
sleep 8
test -n "$(adb shell pidof "$PACKAGE" | tr -d '\r')"

adb shell am force-stop "$PACKAGE"
adb shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1
sleep 6
test -n "$(adb shell pidof "$PACKAGE" | tr -d '\r')"

adb exec-out screencap -p > "$REPORT_DIR/launch-after-restart.png"
adb logcat -b all -d -v threadtime > "$REPORT_DIR/logcat.txt"

if grep -Eq "ANR in $PACKAGE|Process: $PACKAGE.*FATAL" "$REPORT_DIR/logcat.txt"; then
  echo "API 29 smoke detected an app ANR/fatal exception." >&2
  exit 1
fi
