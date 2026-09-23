#!/usr/bin/env bash
set -Eeuo pipefail

APP_ID="${APP_ID:-com.riccardopinato.trail_path}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT_DIR="${REPORT_DIR:-$ROOT_DIR/applab-functional-report}"
START_FLOW="${START_FLOW:-$ROOT_DIR/.maestro/applab-record-start.yaml}"
FINISH_FLOW="${FINISH_FLOW:-$ROOT_DIR/.maestro/applab-record-finish.yaml}"
PERSIST_FLOW="${PERSIST_FLOW:-$ROOT_DIR/.maestro/applab-record-persistence.yaml}"
BACKGROUND_SECONDS="${BACKGROUND_SECONDS:-36}"

GPS_FEED_PID=""

log() {
  printf '[TrailPath functional] %s\n' "$*"
}

write_failure() {
  local reason="$1"
  mkdir -p "$REPORT_DIR"
  {
    echo "# TrailPath functional AppLab report"
    echo
    echo "- Result: FAIL"
    echo "- Reason: $reason"
  } > "$REPORT_DIR/summary.md"
}

cleanup() {
  if [[ -n "$GPS_FEED_PID" ]]; then
    kill "$GPS_FEED_PID" >/dev/null 2>&1 || true
    wait "$GPS_FEED_PID" >/dev/null 2>&1 || true
    GPS_FEED_PID=""
  fi
}

collect_evidence() {
  mkdir -p "$REPORT_DIR"
  adb exec-out screencap -p > "$REPORT_DIR/final.png" 2>/dev/null || true
  adb shell dumpsys activity activities > "$REPORT_DIR/activity.txt" 2>&1 || true
  adb shell dumpsys activity services "$APP_ID" > "$REPORT_DIR/services.txt" 2>&1 || true
  adb shell dumpsys notification --noredact > "$REPORT_DIR/notifications.txt" 2>&1 || true
  adb logcat -b all -d -v threadtime > "$REPORT_DIR/logcat.txt" 2>&1 || true
}

fail() {
  local reason="$1"
  log "ERROR: $reason"
  write_failure "$reason"
  collect_evidence
  cleanup
  exit 1
}

run_maestro() {
  local label="$1"
  local flow="$2"
  local output="$REPORT_DIR/maestro-$label"
  local logfile="$REPORT_DIR/maestro-$label.log"

  mkdir -p "$output"
  log "Maestro $label: $flow"
  if ! maestro test "$flow" --test-output-dir "$output" > "$logfile" 2>&1; then
    cat "$logfile" >&2 || true
    fail "Maestro phase '$label' failed."
  fi
  cat "$logfile"
}

feed_gps() {
  local i phase step lon
  for i in $(seq 0 44); do
    phase=$((i % 18))
    if (( phase > 9 )); then
      step=$((18 - phase))
    else
      step=$phase
    fi
    lon="$(awk -v s="$step" 'BEGIN { printf "%.6f", 11.750000 + (s * 0.00018) }')"
    adb emu geo fix "$lon" 45.232000 90 >/dev/null 2>&1 || true
    sleep 6
  done
}

trap cleanup EXIT INT TERM

command -v adb >/dev/null 2>&1 || fail "adb is not available."
command -v maestro >/dev/null 2>&1 || fail "Maestro is not available."
[[ -f "$START_FLOW" ]] || fail "Missing start flow: $START_FLOW"
[[ -f "$FINISH_FLOW" ]] || fail "Missing finish flow: $FINISH_FLOW"
[[ -f "$PERSIST_FLOW" ]] || fail "Missing persistence flow: $PERSIST_FLOW"

rm -rf "$REPORT_DIR"
mkdir -p "$REPORT_DIR"

log "Preparing Android runtime."
adb wait-for-device
adb shell cmd location set-location-enabled true >/dev/null 2>&1 ||   adb shell settings put secure location_mode 3 >/dev/null 2>&1 || true

adb shell pm grant "$APP_ID" android.permission.ACCESS_FINE_LOCATION >/dev/null 2>&1 || true
adb shell pm grant "$APP_ID" android.permission.ACCESS_COARSE_LOCATION >/dev/null 2>&1 || true
adb shell pm grant "$APP_ID" android.permission.POST_NOTIFICATIONS >/dev/null 2>&1 || true

adb shell am force-stop "$APP_ID" >/dev/null 2>&1 || true
adb logcat -b all -c >/dev/null 2>&1 || true

log "Injecting initial GPS fix."
adb emu geo fix 11.750000 45.232000 90 >/dev/null 2>&1 ||   fail "Android emulator rejected the initial GPS fix."

feed_gps &
GPS_FEED_PID=$!

run_maestro "start" "$START_FLOW"

PID_STARTED="$(adb shell pidof "$APP_ID" 2>/dev/null | tr -d '\r' | awk '{print $1}')"
[[ -n "$PID_STARTED" ]] || fail "TrailPath process is not alive after starting the recording."

log "Sending TrailPath to background for ${BACKGROUND_SECONDS}s while GPS keeps moving."
adb exec-out screencap -p > "$REPORT_DIR/recording-before-background.png" 2>/dev/null || true
adb shell input keyevent KEYCODE_HOME
sleep 8

PID_BACKGROUND="$(adb shell pidof "$APP_ID" 2>/dev/null | tr -d '\r' | awk '{print $1}')"
[[ -n "$PID_BACKGROUND" ]] || fail "TrailPath process died in background."
[[ "$PID_BACKGROUND" == "$PID_STARTED" ]] || fail "TrailPath process restarted while recording in background."

adb shell dumpsys activity services "$APP_ID" > "$REPORT_DIR/background-services.txt" 2>&1 || true
grep -Fq "$APP_ID" "$REPORT_DIR/background-services.txt" ||   fail "No TrailPath location service found while recording in background."

adb shell dumpsys notification --noredact > "$REPORT_DIR/background-notifications.txt" 2>&1 || true
grep -Fq "TrailPath" "$REPORT_DIR/background-notifications.txt" ||   fail "TrailPath foreground recording notification is missing."

sleep "$BACKGROUND_SECONDS"

log "Returning to TrailPath without killing its process."
adb shell monkey -p "$APP_ID" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 ||   fail "Could not reopen TrailPath after background recording."
sleep 4

run_maestro "finish" "$FINISH_FLOW"

log "Cold-restarting the app to verify database persistence."
adb exec-out screencap -p > "$REPORT_DIR/saved-activity.png" 2>/dev/null || true
adb shell am force-stop "$APP_ID"
sleep 2
adb shell monkey -p "$APP_ID" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 ||   fail "Could not cold-start TrailPath for persistence verification."
sleep 5

run_maestro "persistence" "$PERSIST_FLOW"

PID_FINAL="$(adb shell pidof "$APP_ID" 2>/dev/null | tr -d '\r' | awk '{print $1}')"
[[ -n "$PID_FINAL" ]] || fail "TrailPath process is not alive after persistence verification."

collect_evidence

if grep -Fq "ANR in $APP_ID" "$REPORT_DIR/logcat.txt"; then
  fail "ANR detected for $APP_ID."
fi

if grep -F -A 45 "FATAL EXCEPTION" "$REPORT_DIR/logcat.txt" | grep -Fq "Process: $APP_ID"; then
  fail "Fatal exception detected for $APP_ID."
fi

cleanup

{
  echo "# TrailPath functional AppLab report"
  echo
  echo "- Result: PASS"
  echo "- Package: $APP_ID"
  echo "- GPS simulation: PASS"
  echo "- Recording start: PASS"
  echo "- Background process survival: PASS"
  echo "- Foreground location service: PASS"
  echo "- Foreground notification: PASS"
  echo "- Pause/resume: PASS"
  echo "- Activity save: PASS"
  echo "- Cold restart persistence: PASS"
  echo "- PID after verification: $PID_FINAL"
  echo "- ANR: 0"
  echo "- FatalException: 0"
} > "$REPORT_DIR/summary.md"

log "PASS — functional report written to $REPORT_DIR"
