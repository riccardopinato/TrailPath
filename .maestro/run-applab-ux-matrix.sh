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

apply_ux_environment() {
  adb shell wm size 360x640
  adb shell wm density 320
  adb shell settings put system font_scale 1.30
  adb shell pm grant "$APP_ID" android.permission.ACCESS_FINE_LOCATION || true
  adb shell pm grant "$APP_ID" android.permission.ACCESS_COARSE_LOCATION || true
  adb shell pm grant "$APP_ID" android.permission.POST_NOTIFICATIONS || true
  adb emu geo fix 11.7500 45.2320 100 || true
}

adb install -r "$APK"
adb shell pm clear "$APP_ID" >/dev/null || true
apply_ux_environment

FOREIGN_ANR_GUARD_PID=""
cleanup() {
  if [ -n "$FOREIGN_ANR_GUARD_PID" ]; then
    kill "$FOREIGN_ANR_GUARD_PID" >/dev/null 2>&1 || true
    wait "$FOREIGN_ANR_GUARD_PID" >/dev/null 2>&1 || true
  fi
  adb shell wm size reset >/dev/null 2>&1 || true
  adb shell wm density reset >/dev/null 2>&1 || true
  adb shell settings put system font_scale 1.0 >/dev/null 2>&1 || true
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
  "$MAESTRO" test "$ROOT_DIR/.maestro/applab-small-screen-e2e.yaml"     --format junit     --output "$result_xml"     2>&1 | tee "$console_log"
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
    apply_ux_environment
    continue
  fi

  break
done

adb exec-out screencap -p > "$REPORT_DIR/final-planner.png" || true
for attempt in 1 2 3 4; do
  adb shell uiautomator dump /sdcard/trailpath-ux-final.xml >/dev/null 2>&1 || true
  adb pull /sdcard/trailpath-ux-final.xml "$REPORT_DIR/final-planner.xml" >/dev/null 2>&1 || true
  if [ -s "$REPORT_DIR/final-planner.xml" ]; then
    break
  fi
  sleep "$attempt"
done
adb logcat -b all -d -v threadtime > "$REPORT_DIR/logcat.txt" || true

if [ "$maestro_status" -ne 0 ]; then
  exit "$maestro_status"
fi

test -s "$REPORT_DIR/final-planner.png"
test -s "$REPORT_DIR/final-planner.xml"

python3 "$ROOT_DIR/.applab/scripts/visual_qa.py"   --screenshot "$REPORT_DIR/final-planner.png"   --ui-hierarchy "$REPORT_DIR/final-planner.xml"   --package-id "$APP_ID"   --output-json "$REPORT_DIR/visual-qa.json"   --output-md "$REPORT_DIR/visual-qa.md"

python3 "$ROOT_DIR/.applab/scripts/interaction_crawler.py"   --package-id "$APP_ID"   --report-dir "$REPORT_DIR"   --max-actions 6

python3 "$ROOT_DIR/.applab/scripts/performance_lab.py"   --package-id "$APP_ID"   --apk "$APK"   --report-dir "$REPORT_DIR"

if grep -Eq "ANR in com\.riccardopinato\.trail_path|Process: com\.riccardopinato\.trail_path.*FATAL" "$REPORT_DIR/logcat.txt"; then
  exit 1
fi

cat > "$REPORT_DIR/summary.md" <<EOF
# TrailPath AppLab UX Matrix

- Result: PASS
- Viewport: 360x640 logical test window
- Android density override: 320 dpi
- Font scale: 1.30
- Critical surfaces: Planner, Record, Routes, Offline, Profile, Settings
- Smart Visual QA: executed
- Safe Interaction Crawler: executed
- Performance Lab: executed (emulator advisory only)
EOF
