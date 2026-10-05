#!/usr/bin/env bash

trailpath_wait_for_android_runtime() {
  adb wait-for-device >/dev/null 2>&1 || return 1
  local attempt boot
  for attempt in $(seq 1 45); do
    boot="$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)"
    if [ "$boot" = "1" ] &&
       adb shell cmd package list packages android >/dev/null 2>&1 &&
       adb shell service check accessibility >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  return 1
}

trailpath_maestro_failure_is_transient() {
  local console_log="$1"
  local system_log="$2"

  adb logcat -b all -d -v threadtime > "$system_log" 2>&1 || true

  if grep -Eqi     "Broken pipe|Failure calling service package|device offline|device .*not found|ADB server didn't ACK|Connection reset|closed.*transport|transport.*error|Maestro Android driver did not start up in time|AndroidDriverTimeoutException|MaestroDriverStartupException|DeviceServerDiedException|Device server died during|StatusRuntimeException: UNAVAILABLE|Command failed .*: closed|installMaestroDriverApp|UiAutomationService.*already registered|already registered.*UiAutomation|Bad file descriptor"     "$console_log"; then
    return 0
  fi

  if grep -Eqi     "DeadSystemException|The system died|registerUiTestAutomationService.*null object reference|UiAutomationConnection.*NullPointerException|UiAutomationService.*already registered|already registered.*UiAutomation|Bad file descriptor|system_server.*(died|crash|restarting)|ServiceManager.*(dead|Bad file descriptor)"     "$system_log"; then
    return 0
  fi

  return 1
}

trailpath_recover_maestro_runtime() {
  local app_id="$1"
  local driver_package

  adb wait-for-device >/dev/null 2>&1 || true
  adb forward --remove-all >/dev/null 2>&1 || true

  # Dispose stale instrumentation/device-server state before the next Maestro
  # process. These packages are CI-only automation helpers, never TrailPath.
  for driver_package in dev.mobile.maestro dev.mobile.maestro.test com.github.uiautomator; do
    adb shell am force-stop "$driver_package" >/dev/null 2>&1 || true
    adb shell pm clear "$driver_package" >/dev/null 2>&1 || true
  done

  # A dead forwarded socket often leaves the hosted runner's adb daemon in a
  # half-open state even though the emulator process is healthy.
  adb kill-server >/dev/null 2>&1 || true
  adb start-server >/dev/null 2>&1 || true
  adb wait-for-device >/dev/null 2>&1 || true
  trailpath_wait_for_android_runtime || return 1

  adb shell am force-stop "$app_id" >/dev/null 2>&1 || true
  adb shell input keyevent KEYCODE_HOME >/dev/null 2>&1 || true
  sleep 5
  trailpath_wait_for_android_runtime
}
