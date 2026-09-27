#!/usr/bin/env bash
set -uo pipefail

REPORT_ROOT="${GITHUB_WORKSPACE}/applab-report"
OFFLINE_REPORT="${REPORT_ROOT}/offline-maestro"
MAX_INFRA_ATTEMPTS=3
mkdir -p "$OFFLINE_REPORT"

cleanup() {
  adb shell cmd connectivity airplane-mode disable >/dev/null 2>&1 || true
}
trap cleanup EXIT

adb_ready() {
  adb wait-for-device >/dev/null 2>&1 || return 1

  local probe
  for probe in 1 2 3 4 5; do
    if adb shell cmd package list packages >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done

  return 1
}

recover_adb() {
  adb kill-server >/dev/null 2>&1 || true
  adb start-server >/dev/null 2>&1 || true
  adb wait-for-device >/dev/null 2>&1 || true
  sleep 2
  adb_ready
}

is_maestro_infra_failure() {
  local log_file="$1"
  grep -Eq     "AndroidOperationFailedException|Failure calling service package|Broken pipe|device offline|device .* not found|ADB server didn't ACK|Connection reset|installMaestroDriverApp"     "$log_file"
}

if ! adb_ready; then
  echo "Android package manager is not ready before the offline gate." | tee "${REPORT_ROOT}/offline-maestro.log"
  exit 1
fi

attempt=1
while [ "$attempt" -le "$MAX_INFRA_ATTEMPTS" ]; do
  ATTEMPT_LOG="${REPORT_ROOT}/offline-maestro-attempt-${attempt}.log"

  set +e
  maestro test "${GITHUB_WORKSPACE}/.maestro/applab-offline-e2e.yaml"     --test-output-dir "$OFFLINE_REPORT"     2>&1 | tee "$ATTEMPT_LOG"
  STATUS="${PIPESTATUS[0]}"
  set -e

  cp "$ATTEMPT_LOG" "${REPORT_ROOT}/offline-maestro.log"

  if [ "$STATUS" -eq 0 ]; then
    exit 0
  fi

  if [ "$attempt" -lt "$MAX_INFRA_ATTEMPTS" ] && is_maestro_infra_failure "$ATTEMPT_LOG"; then
    echo "Transient ADB/Maestro infrastructure failure on attempt $attempt; recovering ADB before retry."       | tee -a "${REPORT_ROOT}/offline-maestro.log"
    if ! recover_adb; then
      echo "ADB/package-manager recovery failed." | tee -a "${REPORT_ROOT}/offline-maestro.log"
      break
    fi
    attempt=$((attempt + 1))
    continue
  fi

  break
done

adb exec-out screencap -p > "${REPORT_ROOT}/offline-failure.png" || true
adb shell uiautomator dump /sdcard/offline-failure.xml >/dev/null 2>&1 || true
adb pull /sdcard/offline-failure.xml "${REPORT_ROOT}/offline-failure.xml" >/dev/null 2>&1 || true
adb logcat -b all -d -v threadtime > "${REPORT_ROOT}/offline-failure-logcat.txt" 2>&1 || true
exit "${STATUS:-1}"
