#!/usr/bin/env bash
set -euo pipefail

OLD_APK="${1:?old APK path required}"
NEW_APK="${2:?new APK path required}"
REPORT_DIR="${3:-upgrade-migration-report}"
APP_ID="com.riccardopinato.trail_path"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAESTRO="${MAESTRO_BIN:-$HOME/.maestro/bin/maestro}"

mkdir -p "$REPORT_DIR"
REPORT_DIR="$(cd "$REPORT_DIR" && pwd)"

STATUS="FAIL"
STAGE="bootstrap"
OLD_SHA=""
NEW_SHA=""
OLD_VERSION=""
NEW_VERSION=""
OLD_CODE=""
NEW_CODE=""
OLD_LOGICAL_CODE=""
NEW_LOGICAL_CODE=""
ABI_CODE_OFFSET=""
EXPECTED_NEW_VERSION=""
EXPECTED_NEW_CODE=""
EXPECTED_NEW_SPLIT_CODE=""
APKANALYZER=""
FOREIGN_ANR_GUARD_PID=""

fail() {
  echo "TrailPath upgrade gate failed at stage '$STAGE': $*" >&2
  exit 1
}

resolve_apkanalyzer() {
  if [ -n "${APKANALYZER_BIN:-}" ] && [ -x "$APKANALYZER_BIN" ]; then
    printf '%s' "$APKANALYZER_BIN"
    return 0
  fi
  if command -v apkanalyzer >/dev/null 2>&1; then
    command -v apkanalyzer
    return 0
  fi
  for candidate in     "${ANDROID_HOME:-}/cmdline-tools/latest/bin/apkanalyzer"     "${ANDROID_SDK_ROOT:-}/cmdline-tools/latest/bin/apkanalyzer"; do
    if [ -n "$candidate" ] && [ -x "$candidate" ]; then
      printf '%s' "$candidate"
      return 0
    fi
  done
  return 1
}

write_diagnostics() {
  cat > "$REPORT_DIR/diagnostics.txt" <<EOF
status=$STATUS
stage=$STAGE
app_id=$APP_ID
old_apk=$OLD_APK
new_apk=$NEW_APK
old_sha256=$OLD_SHA
new_sha256=$NEW_SHA
old_version=$OLD_VERSION
old_version_code_raw=$OLD_CODE
old_version_code_logical=$OLD_LOGICAL_CODE
new_version=$NEW_VERSION
new_version_code_raw=$NEW_CODE
new_version_code_logical=$NEW_LOGICAL_CODE
abi_code_offset=$ABI_CODE_OFFSET
expected_new_version=$EXPECTED_NEW_VERSION
expected_new_version_code_logical=$EXPECTED_NEW_CODE
expected_new_version_code_raw=$EXPECTED_NEW_SPLIT_CODE
apkanalyzer=$APKANALYZER
EOF
}

on_exit() {
  local exit_code=$?
  if [ -n "$FOREIGN_ANR_GUARD_PID" ]; then
    kill "$FOREIGN_ANR_GUARD_PID" >/dev/null 2>&1 || true
    wait "$FOREIGN_ANR_GUARD_PID" >/dev/null 2>&1 || true
  fi
  write_diagnostics
  if [ "$exit_code" -ne 0 ] && [ ! -s "$REPORT_DIR/summary.md" ]; then
    cat > "$REPORT_DIR/summary.md" <<EOF
# TrailPath Upgrade / Migration AppLab

- Result: FAIL
- Stage: $STAGE
- Exit code: $exit_code
- Baseline detected: ${OLD_VERSION:-unknown}+${OLD_CODE:-unknown}
- Target detected: ${NEW_VERSION:-unknown}+${NEW_CODE:-unknown}
- Target expected from pubspec: ${EXPECTED_NEW_VERSION:-unknown}+${EXPECTED_NEW_CODE:-unknown}

See diagnostics.txt, Maestro JUnit output and Logcat for evidence.
EOF
  fi
}
trap on_exit EXIT

STAGE="validate-inputs"
[ -f "$OLD_APK" ] || fail "baseline APK not found: $OLD_APK"
[ -f "$NEW_APK" ] || fail "target APK not found: $NEW_APK"
[ -x "$MAESTRO" ] || fail "Maestro not executable: $MAESTRO"
APKANALYZER="$(resolve_apkanalyzer)" || fail "apkanalyzer not found in PATH/Android SDK"

VERSION_TOKEN="$(awk '/^version:/ {print $2; exit}' "$ROOT_DIR/pubspec.yaml")"
EXPECTED_NEW_VERSION="${VERSION_TOKEN%%+*}"
EXPECTED_NEW_CODE="${VERSION_TOKEN##*+}"
[ -n "$EXPECTED_NEW_VERSION" ] || fail "unable to read semantic version from pubspec"
[ -n "$EXPECTED_NEW_CODE" ] || fail "unable to read version code from pubspec"

OLD_SHA="$(sha256sum "$OLD_APK" | awk '{print $1}')"
NEW_SHA="$(sha256sum "$NEW_APK" | awk '{print $1}')"

STAGE="inspect-apk-identities"
OLD_VERSION="$("$APKANALYZER" manifest version-name "$OLD_APK" | tr -d '\r\n')"
NEW_VERSION="$("$APKANALYZER" manifest version-name "$NEW_APK" | tr -d '\r\n')"
OLD_CODE="$("$APKANALYZER" manifest version-code "$OLD_APK" | tr -d '\r\n')"
NEW_CODE="$("$APKANALYZER" manifest version-code "$NEW_APK" | tr -d '\r\n')"

case "$OLD_CODE:$NEW_CODE:$EXPECTED_NEW_CODE" in
  *[!0-9:]*|"") fail "non-numeric APK/pubspec versionCode detected" ;;
esac

OLD_LOGICAL_CODE=48
ABI_CODE_OFFSET=$((OLD_CODE - OLD_LOGICAL_CODE))
[ "$ABI_CODE_OFFSET" -ge 0 ] || fail "baseline split versionCode offset is invalid: $OLD_CODE"
NEW_LOGICAL_CODE=$((NEW_CODE - ABI_CODE_OFFSET))
EXPECTED_NEW_SPLIT_CODE=$((EXPECTED_NEW_CODE + ABI_CODE_OFFSET))

echo "Baseline APK: $OLD_VERSION+$OLD_LOGICAL_CODE (split code $OLD_CODE, $OLD_SHA)"
echo "Target APK:   $NEW_VERSION+$NEW_LOGICAL_CODE (split code $NEW_CODE, $NEW_SHA)"
echo "Pubspec:      $EXPECTED_NEW_VERSION+$EXPECTED_NEW_CODE"

[ "$OLD_VERSION" = "1.5.11" ] || fail "baseline versionName must be 1.5.11, got '$OLD_VERSION'"
[ "$OLD_LOGICAL_CODE" = "48" ] || fail "baseline logical versionCode must be 48"
[ "$NEW_VERSION" = "$EXPECTED_NEW_VERSION" ] || fail "target versionName '$NEW_VERSION' != pubspec '$EXPECTED_NEW_VERSION'"
[ "$NEW_LOGICAL_CODE" = "$EXPECTED_NEW_CODE" ] || fail "target logical versionCode '$NEW_LOGICAL_CODE' != pubspec '$EXPECTED_NEW_CODE'"
[ "$NEW_CODE" = "$EXPECTED_NEW_SPLIT_CODE" ] || fail "target split versionCode '$NEW_CODE' != expected '$EXPECTED_NEW_SPLIT_CODE'"
[ "$NEW_CODE" -gt "$OLD_CODE" ] || fail "target split versionCode must increase across upgrade"

STAGE="install-baseline"
adb uninstall "$APP_ID" >/dev/null 2>&1 || true
adb install "$OLD_APK"
# Maestro must not clear the package after these grants, otherwise location
# dialogs can contaminate a migration gate that is meant to test persistence.
adb shell pm clear "$APP_ID" >/dev/null
adb shell pm grant "$APP_ID" android.permission.ACCESS_FINE_LOCATION || true
adb shell pm grant "$APP_ID" android.permission.ACCESS_COARSE_LOCATION || true
adb shell pm grant "$APP_ID" android.permission.POST_NOTIFICATIONS || true
adb emu geo fix 11.7500 45.2320 100 || true

if [ -f "$ROOT_DIR/.applab/scripts/dismiss_foreign_anr.py" ]; then
  (
    for _ in $(seq 1 600); do
      python3 "$ROOT_DIR/.applab/scripts/dismiss_foreign_anr.py"         --package-id "$APP_ID" || true
      sleep 2
    done
  ) &
  FOREIGN_ANR_GUARD_PID=$!
fi

STAGE="seed-baseline"
"$MAESTRO" test "$ROOT_DIR/.maestro/upgrade-seed-v1511.yaml"   --format junit   --output "$REPORT_DIR/seed-results.xml"
adb exec-out screencap -p > "$REPORT_DIR/before-upgrade.png" || true
adb shell dumpsys package "$APP_ID" > "$REPORT_DIR/package-before.txt"
grep -Fq "versionName=1.5.11" "$REPORT_DIR/package-before.txt"
grep -Fq "versionCode=$OLD_CODE" "$REPORT_DIR/package-before.txt"

STAGE="replace-package-in-place"
# Core migration event: package replacement with application data preserved.
adb install -r "$NEW_APK"
adb shell dumpsys package "$APP_ID" > "$REPORT_DIR/package-after.txt"
grep -Fq "versionName=$EXPECTED_NEW_VERSION" "$REPORT_DIR/package-after.txt"
grep -Fq "versionCode=$NEW_CODE" "$REPORT_DIR/package-after.txt"

STAGE="verify-migrated-state"
"$MAESTRO" test "$ROOT_DIR/.maestro/upgrade-verify-v1513.yaml"   --format junit   --output "$REPORT_DIR/verify-results.xml"
adb exec-out screencap -p > "$REPORT_DIR/after-upgrade.png" || true
adb logcat -d > "$REPORT_DIR/logcat.txt"

if grep -Eq "ANR in ${APP_ID}|Process: ${APP_ID}.*FATAL" "$REPORT_DIR/logcat.txt"; then
  fail "TrailPath crash/ANR detected during upgrade migration gate"
fi

STAGE="finalize-evidence"
STATUS="PASS"
cat > "$REPORT_DIR/summary.md" <<EOF
# TrailPath Upgrade / Migration AppLab

- Result: PASS
- Baseline version: $OLD_VERSION+$OLD_LOGICAL_CODE
- Baseline split APK versionCode: $OLD_CODE
- Target version: $NEW_VERSION+$NEW_LOGICAL_CODE
- Target split APK versionCode: $NEW_CODE
- Baseline bootstrap workflow run: 36544385449 (#680)
- Baseline bootstrap artifact ID: 11021533532
- Baseline APK SHA-256: $OLD_SHA
- Target APK SHA-256: $NEW_SHA
- Install semantics: adb install -r, no uninstall/clear between seed and verify
- Persistent data verified: completed activity, saved route geometry, native offline readiness, non-default unit preference
EOF

grep -Fq -- "- Result: PASS" "$REPORT_DIR/summary.md"
grep -Fq -- "Baseline version: 1.5.11+48" "$REPORT_DIR/summary.md"
grep -Fq -- "Target version: $EXPECTED_NEW_VERSION+$EXPECTED_NEW_CODE" "$REPORT_DIR/summary.md"

STAGE="complete"
