#!/usr/bin/env bash
set -euo pipefail

OLD_APK="${1:?old APK path required}"
NEW_APK="${2:?new APK path required}"
REPORT_DIR="${3:-upgrade-migration-report}"
APP_ID="com.riccardopinato.trail_path"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAESTRO="${MAESTRO_BIN:-$HOME/.maestro/bin/maestro}"
APKANALYZER="$ANDROID_HOME/cmdline-tools/latest/bin/apkanalyzer"

mkdir -p "$REPORT_DIR"
REPORT_DIR="$(cd "$REPORT_DIR" && pwd)"

test -f "$OLD_APK"
test -f "$NEW_APK"
test -x "$MAESTRO"
test -x "$APKANALYZER"

OLD_SHA="$(sha256sum "$OLD_APK" | awk '{print $1}')"
NEW_SHA="$(sha256sum "$NEW_APK" | awk '{print $1}')"
OLD_VERSION="$("$APKANALYZER" manifest version-name "$OLD_APK")"
NEW_VERSION="$("$APKANALYZER" manifest version-name "$NEW_APK")"
OLD_CODE="$("$APKANALYZER" manifest version-code "$OLD_APK")"
NEW_CODE="$("$APKANALYZER" manifest version-code "$NEW_APK")"

test "$OLD_VERSION" = "1.5.11"
test "$OLD_CODE" = "48"
test "$NEW_VERSION" = "1.5.13"
test "$NEW_CODE" = "50"

adb uninstall "$APP_ID" >/dev/null 2>&1 || true
adb install "$OLD_APK"
adb shell pm grant "$APP_ID" android.permission.ACCESS_FINE_LOCATION || true
adb shell pm grant "$APP_ID" android.permission.ACCESS_COARSE_LOCATION || true
adb shell pm grant "$APP_ID" android.permission.POST_NOTIFICATIONS || true
adb emu geo fix 11.7500 45.2320 100 || true

"$MAESTRO" test "$ROOT_DIR/.maestro/upgrade-seed-v1511.yaml"   --format junit   --output "$REPORT_DIR/seed-results.xml"
adb exec-out screencap -p > "$REPORT_DIR/before-upgrade.png" || true
adb shell dumpsys package "$APP_ID" > "$REPORT_DIR/package-before.txt"
grep -Fq "versionName=1.5.11" "$REPORT_DIR/package-before.txt"
grep -Fq "versionCode=48" "$REPORT_DIR/package-before.txt"

# Core migration event: package replacement with application data preserved.
adb install -r "$NEW_APK"
adb shell dumpsys package "$APP_ID" > "$REPORT_DIR/package-after.txt"
grep -Fq "versionName=1.5.13" "$REPORT_DIR/package-after.txt"
grep -Fq "versionCode=50" "$REPORT_DIR/package-after.txt"

"$MAESTRO" test "$ROOT_DIR/.maestro/upgrade-verify-v1513.yaml"   --format junit   --output "$REPORT_DIR/verify-results.xml"
adb exec-out screencap -p > "$REPORT_DIR/after-upgrade.png" || true
adb logcat -d > "$REPORT_DIR/logcat.txt"

if grep -Eq "ANR in ${APP_ID}|Process: ${APP_ID}.*FATAL" "$REPORT_DIR/logcat.txt"; then
  echo "TrailPath crash/ANR detected during upgrade migration gate." >&2
  exit 1
fi

cat > "$REPORT_DIR/summary.md" <<EOF
# TrailPath Upgrade / Migration AppLab

- Result: PASS
- Baseline version: $OLD_VERSION+$OLD_CODE
- Target version: $NEW_VERSION+$NEW_CODE
- Baseline workflow run: 36544385449 (#680)
- Baseline artifact ID: 11021533532
- Baseline original APK SHA-256: $OLD_SHA
- Target original APK SHA-256: $NEW_SHA
- Install semantics: adb install -r, no uninstall/clear between seed and verify
- Persistent data verified: completed activity, saved route geometry, native offline readiness, non-default unit preference
EOF

grep -Fq -- "- Result: PASS" "$REPORT_DIR/summary.md"
grep -Fq -- "Baseline version: 1.5.11+48" "$REPORT_DIR/summary.md"
grep -Fq -- "Target version: 1.5.13+50" "$REPORT_DIR/summary.md"
