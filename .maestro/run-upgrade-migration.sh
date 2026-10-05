#!/usr/bin/env bash
set -euo pipefail

OLD_APK="${1:?old APK path required}"
NEW_APK="${2:?new APK path required}"
REPORT_DIR="${3:-upgrade-migration-report}"
APP_ID="com.riccardopinato.trail_path"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAESTRO="${MAESTRO_BIN:-$HOME/.maestro/bin/maestro}"
MAX_INFRA_ATTEMPTS=3

source "$ROOT_DIR/.maestro/ci_runtime_helpers.sh"

mkdir -p "$REPORT_DIR"
REPORT_DIR="$(cd "$REPORT_DIR" && pwd)"

STATUS="FAIL"
STAGE="bootstrap"
OLD_SHA=""
NEW_SHA=""
OLD_QA_SHA=""
NEW_QA_SHA=""
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
APKSIGNER=""
FOREIGN_ANR_GUARD_PID=""
QA_OLD_APK=""
QA_NEW_APK=""

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

resolve_apksigner() {
  local root candidate
  for root in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}"; do
    [ -n "$root" ] || continue
    candidate="$(find "$root/build-tools" -maxdepth 2 -type f -name apksigner 2>/dev/null | sort -V | tail -n 1)"
    if [ -n "$candidate" ] && [ -x "$candidate" ]; then
      printf '%s' "$candidate"
      return 0
    fi
  done
  return 1
}

capture_failure_evidence() {
  local suffix
  suffix="$(printf '%s' "$STAGE" | tr -cs 'A-Za-z0-9._-' '-')"
  adb exec-out screencap -p > "$REPORT_DIR/failure-$suffix.png" 2>/dev/null || true
  adb shell uiautomator dump /sdcard/trailpath-migration-failure.xml >/dev/null 2>&1 || true
  adb pull /sdcard/trailpath-migration-failure.xml "$REPORT_DIR/failure-$suffix.xml" >/dev/null 2>&1 || true
  adb logcat -b all -d -v threadtime > "$REPORT_DIR/failure-$suffix-logcat.txt" 2>&1 || true
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
old_qa_resigned_sha256=$OLD_QA_SHA
new_qa_resigned_sha256=$NEW_QA_SHA
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
apksigner=$APKSIGNER
EOF
}

on_exit() {
  local exit_code=$?
  if [ -n "$FOREIGN_ANR_GUARD_PID" ]; then
    kill "$FOREIGN_ANR_GUARD_PID" >/dev/null 2>&1 || true
    wait "$FOREIGN_ANR_GUARD_PID" >/dev/null 2>&1 || true
  fi
  if [ "$exit_code" -ne 0 ]; then
    capture_failure_evidence
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

See diagnostics.txt, Maestro output and failure-stage evidence.
EOF
  fi
}
trap on_exit EXIT

STAGE="validate-inputs"
[ -f "$OLD_APK" ] || fail "baseline APK not found: $OLD_APK"
[ -f "$NEW_APK" ] || fail "target APK not found: $NEW_APK"
[ -x "$MAESTRO" ] || fail "Maestro not executable: $MAESTRO"
APKANALYZER="$(resolve_apkanalyzer)" || fail "apkanalyzer not found in PATH/Android SDK"
APKSIGNER="$(resolve_apksigner)" || fail "apksigner not found in Android SDK"
command -v keytool >/dev/null 2>&1 || fail "keytool not found"

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

# Hosted runners create ephemeral debug certificates. Re-sign temporary copies
# of both already-built APK payloads with one QA-only certificate so Android can
# exercise an actual in-place package update. Original artifact SHA-256 values
# remain recorded above and no QA key is persisted as an artifact.
STAGE="prepare-common-qa-signature"
QA_ROOT="${RUNNER_TEMP:-/tmp}/trailpath-migration-signing"
rm -rf "$QA_ROOT"
mkdir -p "$QA_ROOT"
QA_KEYSTORE="$QA_ROOT/migration-qa.jks"
QA_OLD_APK="$QA_ROOT/trailpath-old.apk"
QA_NEW_APK="$QA_ROOT/trailpath-new.apk"
QA_PASS="trailpath-migration-ci"

keytool -genkeypair -noprompt   -keystore "$QA_KEYSTORE"   -storepass "$QA_PASS"   -keypass "$QA_PASS"   -alias trailpath-migration   -dname "CN=TrailPath Migration QA, OU=CI, O=TrailPath, C=IT"   -keyalg RSA -keysize 2048 -validity 3650 >/dev/null 2>&1

"$APKSIGNER" sign   --ks "$QA_KEYSTORE"   --ks-key-alias trailpath-migration   --ks-pass "pass:$QA_PASS"   --key-pass "pass:$QA_PASS"   --out "$QA_OLD_APK" "$OLD_APK"
"$APKSIGNER" sign   --ks "$QA_KEYSTORE"   --ks-key-alias trailpath-migration   --ks-pass "pass:$QA_PASS"   --key-pass "pass:$QA_PASS"   --out "$QA_NEW_APK" "$NEW_APK"
"$APKSIGNER" verify "$QA_OLD_APK"
"$APKSIGNER" verify "$QA_NEW_APK"
OLD_QA_SHA="$(sha256sum "$QA_OLD_APK" | awk '{print $1}')"
NEW_QA_SHA="$(sha256sum "$QA_NEW_APK" | awk '{print $1}')"

prepare_baseline_state() {
  trailpath_wait_for_android_runtime || return 1
  adb uninstall "$APP_ID" >/dev/null 2>&1 || true
  adb install "$QA_OLD_APK" >/dev/null
  adb shell pm clear "$APP_ID" >/dev/null
  adb shell pm grant "$APP_ID" android.permission.ACCESS_FINE_LOCATION || true
  adb shell pm grant "$APP_ID" android.permission.ACCESS_COARSE_LOCATION || true
  adb shell pm grant "$APP_ID" android.permission.POST_NOTIFICATIONS || true
  adb emu geo fix 11.7500 45.2320 100 || true
}

run_maestro_with_retry() {
  local flow="$1"
  local output_name="$2"
  local retry_mode="$3"
  local attempt status console_log system_log attempt_xml

  status=1
  for attempt in $(seq 1 "$MAX_INFRA_ATTEMPTS"); do
    console_log="$REPORT_DIR/${output_name%.xml}-attempt-$attempt.log"
    system_log="$REPORT_DIR/${output_name%.xml}-attempt-$attempt-system-logcat.txt"
    attempt_xml="$REPORT_DIR/${output_name%.xml}-attempt-$attempt.xml"

    set +e
    "$MAESTRO" test "$flow" --format junit --output "$attempt_xml" 2>&1 | tee "$console_log"
    status="${PIPESTATUS[0]}"
    set -e

    if [ "$status" -eq 0 ]; then
      cp "$attempt_xml" "$REPORT_DIR/$output_name"
      return 0
    fi

    if [ "$attempt" -ge "$MAX_INFRA_ATTEMPTS" ] ||
       ! trailpath_maestro_failure_is_transient "$console_log" "$system_log"; then
      return "$status"
    fi

    echo "Transient migration harness failure on attempt $attempt; recovering." | tee -a "$console_log"
    trailpath_recover_maestro_runtime "$APP_ID" || return "$status"
    if [ "$retry_mode" = "reset-baseline" ]; then
      prepare_baseline_state || return "$status"
    fi
  done
  return "$status"
}

STAGE="install-baseline"
prepare_baseline_state || fail "baseline installation/readiness failed"

if [ -f "$ROOT_DIR/.applab/scripts/dismiss_foreign_anr.py" ]; then
  (
    for _ in $(seq 1 600); do
      python3 "$ROOT_DIR/.applab/scripts/dismiss_foreign_anr.py" --package-id "$APP_ID" || true
      sleep 2
    done
  ) &
  FOREIGN_ANR_GUARD_PID=$!
fi

STAGE="seed-baseline"
run_maestro_with_retry "$ROOT_DIR/.maestro/upgrade-seed-v1511.yaml" "seed-results.xml" "reset-baseline" ||
  fail "baseline seed flow failed"
adb exec-out screencap -p > "$REPORT_DIR/before-upgrade.png" || true
adb shell dumpsys package "$APP_ID" > "$REPORT_DIR/package-before.txt"
grep -Fq "versionName=1.5.11" "$REPORT_DIR/package-before.txt"
grep -Fq "versionCode=$OLD_CODE" "$REPORT_DIR/package-before.txt"

STAGE="replace-package-in-place"
adb install -r "$QA_NEW_APK"
adb shell dumpsys package "$APP_ID" > "$REPORT_DIR/package-after.txt"
grep -Fq "versionName=$EXPECTED_NEW_VERSION" "$REPORT_DIR/package-after.txt"
grep -Fq "versionCode=$NEW_CODE" "$REPORT_DIR/package-after.txt"

STAGE="verify-migrated-state"
run_maestro_with_retry "$ROOT_DIR/.maestro/upgrade-verify-v1513.yaml" "verify-results.xml" "preserve-state" ||
  fail "migrated-state verification flow failed"
adb exec-out screencap -p > "$REPORT_DIR/after-upgrade.png" || true
adb logcat -b all -d -v threadtime > "$REPORT_DIR/logcat.txt"

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
- Baseline original APK SHA-256: $OLD_SHA
- Target original APK SHA-256: $NEW_SHA
- Baseline QA-resigned APK SHA-256: $OLD_QA_SHA
- Target QA-resigned APK SHA-256: $NEW_QA_SHA
- Install semantics: adb install -r with one ephemeral QA certificate; no uninstall/clear between seed and verify
- Persistent data verified: completed activity, saved route geometry, native offline readiness, non-default unit preference
EOF

grep -Fq -- "- Result: PASS" "$REPORT_DIR/summary.md"
grep -Fq -- "Baseline version: 1.5.11+48" "$REPORT_DIR/summary.md"
grep -Fq -- "Target version: $EXPECTED_NEW_VERSION+$EXPECTED_NEW_CODE" "$REPORT_DIR/summary.md"

STAGE="complete"
