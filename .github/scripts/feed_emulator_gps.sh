#!/usr/bin/env bash
set -u

# Keep feeding realistic emulator positions for the whole AppLab functional test.
# adb emu geo fix expects: longitude latitude [altitude].
points=(
  "11.7500 45.2320"
  "11.7502 45.2322"
  "11.7504 45.2324"
  "11.7506 45.2326"
  "11.7508 45.2328"
  "11.7510 45.2330"
  "11.7512 45.2332"
  "11.7514 45.2334"
  "11.7516 45.2336"
  "11.7518 45.2338"
)

# Give the application/emulator a first stable fix immediately.
adb emu geo fix 11.7500 45.2320 >/dev/null 2>&1 || true
sleep 2

# Walk the path forward/backward at ~15 m/s, comfortably below TrailPath's
# impossible-speed rejection threshold. Keep it alive long enough for Maestro.
for cycle in $(seq 1 18); do
  for point in "${points[@]}"; do
    adb emu geo fix $point >/dev/null 2>&1 || true
    sleep 2
  done

  for ((i=${#points[@]}-2; i>=1; i--)); do
    adb emu geo fix ${points[$i]} >/dev/null 2>&1 || true
    sleep 2
  done
done
