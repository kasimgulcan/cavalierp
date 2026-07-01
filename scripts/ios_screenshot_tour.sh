#!/usr/bin/env bash
# Capture App Store screenshots: build the native Runner.app once, then run each
# screen via `flutter run --use-application-binary` (skips the slow Xcode step)
# with its own --dart-define values. --dart-define is applied at Dart compile
# time on every flutter run, so per-screen route/tab values are honored even
# though the native binary is shared.
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

# Build the native app shell once (slow Xcode step). Every capture then reuses
# it via --use-application-binary and only recompiles the Dart side per screen
# (fast, and --dart-define is applied at Dart compile time on every flutter run,
# so the values are honored despite the shared binary).
echo "=== Building iOS simulator app shell (once) ==="
flutter build ios --simulator --debug 2>&1 | tail -30 || true

APP_PATH=$(find "$ROOT/mobile/build/ios/iphonesimulator" -name "Runner.app" -type d | head -1)
if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
  echo "Runner.app not found after build"
  exit 1
fi
echo "Using prebuilt app: $APP_PATH"

capture() {
  local name="$1"
  local route="$2"
  local auto_login="$3"
  local tab="$4"
  local log="$OUT_DIR/flutter-${name}.log"

  echo "=== Capturing $name (route=$route tab=$tab auto_login=$auto_login) ==="
  : > "$log"

  flutter run -d "$DEVICE_ID" --use-application-binary="$APP_PATH" \
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
