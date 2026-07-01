#!/usr/bin/env bash
# One build, then per-screen config JSON + simctl launch + screenshot.
set -euo pipefail

DEVICE_ID="${1:?device udid required}"
EMAIL="${2:-}"
PASSWORD="${3:-}"
OUT_DIR="${4:-collected-screenshots}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE_ID="com.kocapanda.cavalierp"
mkdir -p "$OUT_DIR"
cd "$ROOT/mobile"

xcrun simctl privacy "$DEVICE_ID" grant camera "$BUNDLE_ID" 2>/dev/null || true

echo "=== Building iOS simulator app (tour mode) ==="
flutter build ios --simulator --debug --dart-define=SCREENSHOT_TOUR=true

APP_PATH=$(find "$ROOT/mobile/build/ios/iphonesimulator" -name "Runner.app" -type d | head -1)
if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
  echo "Runner.app not found after build"
  exit 1
fi
echo "Using app: $APP_PATH"

xcrun simctl install "$DEVICE_ID" "$APP_PATH"

push_config() {
  local route="$1"
  local tab="$2"
  local auto_login="$3"
  local container

  container=$(xcrun simctl get_app_container "$DEVICE_ID" "$BUNDLE_ID" data)
  mkdir -p "$container/Documents"

  SCREENSHOT_ROUTE="$route" \
  SCREENSHOT_TAB="$tab" \
  SCREENSHOT_AUTO_LOGIN="$auto_login" \
  SCREENSHOT_EMAIL="$EMAIL" \
  SCREENSHOT_PASSWORD="$PASSWORD" \
  SCREENSHOT_CONFIG_PATH="$container/Documents/screenshot_config.json" \
  python3 <<'PY'
import json, os, pathlib

path = pathlib.Path(os.environ["SCREENSHOT_CONFIG_PATH"])
path.write_text(
    json.dumps(
        {
            "route": os.environ["SCREENSHOT_ROUTE"],
            "tab": int(os.environ["SCREENSHOT_TAB"]),
            "autoLogin": os.environ["SCREENSHOT_AUTO_LOGIN"] == "true",
            "email": os.environ.get("SCREENSHOT_EMAIL", ""),
            "password": os.environ.get("SCREENSHOT_PASSWORD", ""),
        },
        ensure_ascii=False,
    ),
    encoding="utf-8",
)
print(f"Config: route={os.environ['SCREENSHOT_ROUTE']} tab={os.environ['SCREENSHOT_TAB']}")
PY
}

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

  push_config "$route" "$tab" "$auto_login"
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
