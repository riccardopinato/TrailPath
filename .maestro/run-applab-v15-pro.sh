#!/usr/bin/env bash
set -euo pipefail

APK="${1:?APK path required}"
REPORT_DIR="${2:?report dir required}"
APP_ID="com.riccardopinato.trail_path"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAESTRO="${MAESTRO_BIN:-$HOME/.maestro/bin/maestro}"
MAX_INFRA_ATTEMPTS=3

source "$ROOT_DIR/.maestro/ci_runtime_helpers.sh"

mkdir -p "$REPORT_DIR"
test -f "$APK"
test -x "$MAESTRO"
trailpath_wait_for_android_runtime

adb install -r "$APK"
adb shell pm clear "$APP_ID" >/dev/null || true
adb shell pm grant "$APP_ID" android.permission.ACCESS_FINE_LOCATION || true
adb shell pm grant "$APP_ID" android.permission.ACCESS_COARSE_LOCATION || true
adb shell pm grant "$APP_ID" android.permission.POST_NOTIFICATIONS || true
adb emu geo fix 11.7500 45.2320 100 || true

FOREIGN_ANR_GUARD_PID=""
cleanup() {
  if [ -n "$FOREIGN_ANR_GUARD_PID" ]; then
    kill "$FOREIGN_ANR_GUARD_PID" >/dev/null 2>&1 || true
    wait "$FOREIGN_ANR_GUARD_PID" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

if [ -f "$ROOT_DIR/.applab/scripts/dismiss_foreign_anr.py" ]; then
  (
    for _ in $(seq 1 180); do
      python3 "$ROOT_DIR/.applab/scripts/dismiss_foreign_anr.py" --package-id "$APP_ID" || true
      sleep 1
    done
  ) &
  FOREIGN_ANR_GUARD_PID=$!
fi

maestro_status=1
for attempt in $(seq 1 "$MAX_INFRA_ATTEMPTS"); do
  console_log="$REPORT_DIR/maestro-attempt-$attempt.log"
  system_log="$REPORT_DIR/maestro-attempt-$attempt-system-logcat.txt"
  result_xml="$REPORT_DIR/results-attempt-$attempt.xml"

  set +e
  "$MAESTRO" test "$ROOT_DIR/.maestro/applab-v15-pro-e2e.yaml"     --format junit     --output "$result_xml"     2>&1 | tee "$console_log"
  maestro_status="${PIPESTATUS[0]}"
  set -e

  if [ "$maestro_status" -eq 0 ]; then
    cp "$result_xml" "$REPORT_DIR/results.xml"
    break
  fi

  if [ "$attempt" -lt "$MAX_INFRA_ATTEMPTS" ] &&
     trailpath_maestro_failure_is_transient "$console_log" "$system_log"; then
    echo "Transient Maestro/Android infrastructure failure on attempt $attempt; retrying." | tee -a "$console_log"
    trailpath_recover_maestro_runtime "$APP_ID"
    adb shell pm grant "$APP_ID" android.permission.ACCESS_FINE_LOCATION || true
    adb shell pm grant "$APP_ID" android.permission.ACCESS_COARSE_LOCATION || true
    adb shell pm grant "$APP_ID" android.permission.POST_NOTIFICATIONS || true
    adb emu geo fix 11.7500 45.2320 100 || true
    continue
  fi

  break
done

adb exec-out screencap -p > "$REPORT_DIR/final.png" || true
adb shell uiautomator dump /sdcard/trailpath-v15-final.xml >/dev/null 2>&1 || true
adb pull /sdcard/trailpath-v15-final.xml "$REPORT_DIR/final.xml" >/dev/null 2>&1 || true
adb logcat -b all -d -v threadtime > "$REPORT_DIR/logcat.txt" || true

crash_status=0
if grep -Eq "ANR in com\.riccardopinato\.trail_path|Process: com\.riccardopinato\.trail_path.*FATAL" "$REPORT_DIR/logcat.txt"; then
  crash_status=1
fi

if [ "$maestro_status" -ne 0 ]; then
  exit "$maestro_status"
fi
exit "$crash_status"
