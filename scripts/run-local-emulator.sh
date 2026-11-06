#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
wsl_address="$(hostname -I | awk '{print $1}')"
backend_pid=""
backend_log="$project_dir/backend/.local-data/backend.log"

cleanup() {
  if [[ -n "$backend_pid" ]] && kill -0 "$backend_pid" 2>/dev/null; then
    kill "$backend_pid" 2>/dev/null || true
    wait "$backend_pid" 2>/dev/null || true
  fi
}

trap cleanup EXIT INT TERM

if [[ -z "$wsl_address" ]]; then
  echo "Could not determine the WSL address." >&2
  exit 1
fi

if ! curl --fail --silent --max-time 2 \
  "http://127.0.0.1:8080/api/v1/health" >/dev/null; then
  echo "Starting the Oyla backend..."
  if [[ -f "$project_dir/backend/.local-data/oyla.mv.db" ]]; then
    backup_dir="$project_dir/backend/.local-data/pre-mvp-backup"
    mkdir -p "$backup_dir"
    if [[ ! -f "$backup_dir/oyla.mv.db" ]]; then
      cp -p "$project_dir/backend/.local-data/oyla.mv.db" "$backup_dir/oyla.mv.db"
    fi
  fi
  mkdir -p "$(dirname "$backend_log")"
  (
    cd "$project_dir/backend"
    exec ./gradlew bootRun --args='--spring.profiles.active=local'
  ) >"$backend_log" 2>&1 &
  backend_pid="$!"

  for _ in {1..60}; do
    if curl --fail --silent --max-time 1 \
      "http://127.0.0.1:8080/api/v1/health" >/dev/null; then
      break
    fi
    if ! kill -0 "$backend_pid" 2>/dev/null; then
      echo "The Oyla backend failed to start. Recent output:" >&2
      tail -n 30 "$backend_log" >&2
      exit 1
    fi
    sleep 0.5
  done

  if ! curl --fail --silent --max-time 2 \
    "http://127.0.0.1:8080/api/v1/health" >/dev/null; then
    echo "Timed out waiting for the Oyla backend. See $backend_log" >&2
    exit 1
  fi
fi

if ! adb shell "timeout 5 nc -z $wsl_address 8080" >/dev/null 2>&1; then
  echo "The emulator cannot reach the backend at $wsl_address:8080." >&2
  echo "Allow Java/port 8080 through Windows Firewall, then try again." >&2
  exit 1
fi

echo "Connecting the emulator to the backend at $wsl_address:8080"
cd "$project_dir/mobile"
installed_version="$(adb -s emulator-5554 shell dumpsys package com.oyla.app 2>/dev/null \
  | sed -n 's/.*versionCode=\([0-9][0-9]*\).*/\1/p' | head -n 1 | tr -d '\r')"
build_number=1
if [[ "$installed_version" =~ ^[0-9]+$ ]] && (( installed_version >= build_number )); then
  build_number=$((installed_version + 1))
fi
emulator_abi="$(adb -s emulator-5554 shell getprop ro.product.cpu.abi | tr -d '\r')"
case "$emulator_abi" in
  x86_64) emulator_target=android-x64 ;;
  arm64-v8a) emulator_target=android-arm64 ;;
  *) emulator_target=android-arm ;;
esac
flutter build apk --debug --target-platform="$emulator_target" \
  --build-number="$build_number" \
  --dart-define="OYLA_API_URL=http://$wsl_address:8080/api/v1"
if ! install_output="$(adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk 2>&1)"; then
  if [[ "$install_output" == *"INSTALL_FAILED_INSUFFICIENT_STORAGE"* ]]; then
    python3 "$project_dir/scripts/install-emulator-apk.py" build/app/outputs/flutter-apk/app-debug.apk
  else
    echo "$install_output" >&2
    exit 1
  fi
else
  echo "$install_output"
fi
adb -s emulator-5554 shell am force-stop com.oyla.app
adb -s emulator-5554 shell am start -W -n com.oyla.app/.MainActivity >/dev/null

echo "Oyla is running. Keep this terminal open; press Ctrl+C to stop."
while adb -s emulator-5554 shell pidof com.oyla.app >/dev/null 2>&1; do
  if [[ -n "$backend_pid" ]] && ! kill -0 "$backend_pid" 2>/dev/null; then
    echo "The Oyla backend stopped unexpectedly. See $backend_log" >&2
    exit 1
  fi
  sleep 2
done
