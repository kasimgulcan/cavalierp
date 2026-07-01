#!/usr/bin/env bash
# One iOS simulator build, then capture screens via simctl launch + env vars.
set -euo pipefail

DEVICE_ID="${1:?device udid required}"
EMAIL="${2:-}"
PASSWORD="${3:-}"
OUT_DIR="${4:-collected-screenshots}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE_ID="com.kocapanda.cavalierp"
mkdir -p "$OUT_DIR"

echo "=== Building iOS simulator app (once) ==="
cd "$ROOT/mobile"
flutter build ios --simulator --debug \
  --dart-define=SCREENSHOT_TOUR=true \
  --dart-define=SCREENSHOT_EMAIL="$EMAIL" \
  --dart-define=SCREENSHOT_PASSWORD="$PASSWORD"

APP_PATH=$(find "$ROOT/mobile/build/ios/iphonesimulator" -name "Runner.app" -type d | head -1)
if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
  echo "Runner.app not found after build"
  exit 1
fi
echo "Using app: $APP_PATH"

xcrun simctl install "$DEVICE_ID" "$APP_PATH"

# Pre-grant camera permission so the scanner screen never blocks on an
# unattended system permission dialog during the tour.
xcrun simctl privacy "$DEVICE_ID" grant camera "$BUNDLE_ID" 2>/dev/null || true

capture() {
  local name="$1"
  local route="$2"
  local auto_login="$3"
  local tab="$4"
  local log="$OUT_DIR/flutter-${name}.log"

  echo "=== Capturing $name (route=$route tab=$tab auto_login=$auto_login) ==="
  : > "$log"

  xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" 2>/dev/null || true
  sleep 2

  SIMCTL_CHILD_SCREENSHOT_ROUTE="$route" \
  SIMCTL_CHILD_SCREENSHOT_TAB="$tab" \
  SIMCTL_CHILD_SCREENSHOT_AUTO_LOGIN="$auto_login" \
  SIMCTL_CHILD_SCREENSHOT_EMAIL="$EMAIL" \
  SIMCTL_CHILD_SCREENSHOT_PASSWORD="$PASSWORD" \
  xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID" >> "$log" 2>&1 || true

  bash "$ROOT/scripts/ios_wait_and_screenshot.sh" \
    "$DEVICE_ID" \
    "$OUT_DIR" \
    "$name" \
    "$log" \
    "simctl" \
    "$auto_login" || return 1

  xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" 2>/dev/null || true
  sleep 1
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
