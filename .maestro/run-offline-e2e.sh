#!/usr/bin/env bash
set -uo pipefail

REPORT_ROOT="${GITHUB_WORKSPACE}/applab-report"
OFFLINE_REPORT="${REPORT_ROOT}/offline-maestro"
mkdir -p "$OFFLINE_REPORT"

cleanup() {
  adb shell cmd connectivity airplane-mode disable >/dev/null 2>&1 || true
}
trap cleanup EXIT

set +e
maestro test "${GITHUB_WORKSPACE}/.maestro/applab-offline-e2e.yaml" \
  --test-output-dir "$OFFLINE_REPORT" \
  2>&1 | tee "${REPORT_ROOT}/offline-maestro.log"
STATUS="${PIPESTATUS[0]}"
set -e

if [ "$STATUS" -ne 0 ]; then
  adb exec-out screencap -p > "${REPORT_ROOT}/offline-failure.png" || true
  adb shell uiautomator dump /sdcard/offline-failure.xml >/dev/null 2>&1 || true
  adb pull /sdcard/offline-failure.xml "${REPORT_ROOT}/offline-failure.xml" >/dev/null 2>&1 || true
  adb logcat -b all -d -v threadtime > "${REPORT_ROOT}/offline-failure-logcat.txt" 2>&1 || true
  exit "$STATUS"
fi
