#!/usr/bin/env bash
# Capture App Store screenshots: first screen does a full flutter run (native
# build), subsequent screens reuse the resulting Runner.app via
# --use-application-binary and only recompile the Dart side per --dart-define
# (fast, and --dart-define is honored correctly since it's applied at Dart
# compile time on every `flutter run`, regardless of binary reuse).
set -euo pipefail

DEVICE_ID="${1:?device udid required}"
EMAIL="${2:-}"
PASSWORD="${3:-}"
OUT_DIR="${4:-collected-screenshots}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE_ID="com.kocapanda.cavalierp"
mkdir -p "$OUT_DIR"
cd "$ROOT/mobile"

# Pre-grant camera permission so the scanner screen never blocks on an
# unattended system permission dialog during the tour.
xcrun simctl privacy "$DEVICE_ID" grant camera "$BUNDLE_ID" 2>/dev/null || true

APP_PATH=""

capture() {
  local name="$1"
  local route="$2"
  local auto_login="$3"
  local tab="$4"
  local log="$OUT_DIR/flutter-${name}.log"

  echo "=== Capturing $name (route=$route tab=$tab auto_login=$auto_login) ==="
  : > "$log"

  local extra_args=()
  if [ -n "$APP_PATH" ]; then
    extra_args+=(--use-application-binary="$APP_PATH")
  fi

  flutter run -d "$DEVICE_ID" "${extra_args[@]}" \
    --dart-define=SCREENSHOT_ROUTE="$route" \
    --dart-define=SCREENSHOT_TAB="$tab" \
    --dart-define=SCREENSHOT_AUTO_LOGIN="$auto_login" \
    --dart-define=SCREENSHOT_EMAIL="$EMAIL" \
    --dart-define=SCREENSHOT_PASSWORD="$PASSWORD" \
    >> "$log" 2>&1 &
  local pid=$!

  bash "$ROOT/scripts/ios_wait_and_screenshot.sh" \
    "$DEVICE_ID" \
    "$OUT_DIR" \
    "$name" \
    "$log" \
    "$auto_login" || {
      kill -INT "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
      return 1
    }

  kill -INT "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  sleep 2

  if [ -z "$APP_PATH" ]; then
    APP_PATH=$(find "$ROOT/mobile/build/ios/iphonesimulator" -name "Runner.app" -type d | head -1)
    echo "Resolved prebuilt app for reuse: $APP_PATH"
  fi
}

failed=0

capture "01-login" "/login" "false" "0" || failed=$((failed + 1))
capture "02-register" "/register" "false" "0" || failed=$((failed + 1))

if [ -n "$EMAIL" ] && [ -n "$PASSWORD" ]; then
  capture "03-products" "/home" "true" "0" || failed=$((failed + 1))
  capture "04-cart" "/home" "true" "1" || failed=$((failed + 1))
  capture "05-scanner" "/home" "true" "2" || failed=$((failed + 1))
  capture "06-profile" "/home" "true" "3" || failed=$((failed + 1))
else
  echo "::warning::SCREENSHOT_EMAIL/PASSWORD not set — skipping authenticated screens."
fi

bash "$ROOT/scripts/gather_screenshots.sh" "$OUT_DIR"
count=$(find "$OUT_DIR" -maxdepth 1 -name '*.png' 2>/dev/null | wc -l | tr -d ' ')
echo "Screenshot tour complete: $count PNG(s), $failed capture failure(s)"
[ "$count" -ge 1 ]
