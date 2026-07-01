#!/usr/bin/env bash
# Run integration_test on iOS simulator (correct runner for takeScreenshot).
set -euo pipefail

DEVICE_ID="${1:?device udid required}"
EMAIL="${2:-}"
PASSWORD="${3:-}"
LOG="${4:-flutter-test.log}"
OUT_DIR="${5:-collected-screenshots}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/mobile"
mkdir -p "$OUT_DIR"
: > "$LOG"

echo "Running integration_test on device $DEVICE_ID..."
set +e
flutter test integration_test/app_screenshots_test.dart \
  -d "$DEVICE_ID" \
  --dart-define=SCREENSHOT_EMAIL="$EMAIL" \
  --dart-define=SCREENSHOT_PASSWORD="$PASSWORD" \
  >> "$LOG" 2>&1
test_exit=$?
set -e

bash "$ROOT/scripts/gather_screenshots.sh" "$OUT_DIR"
final=$(find "$OUT_DIR" -maxdepth 1 -name '*.png' 2>/dev/null | wc -l | tr -d ' ')
echo "Total screenshots in output: $final (flutter test exit: $test_exit)"

if [ "$final" -lt 1 ]; then
  echo "Test log tail:"
  tail -80 "$LOG" || true
  exit 1
fi

# Accept partial success if at least 2 screenshots (login + register minimum).
if [ "$test_exit" -ne 0 ] && [ "$final" -lt 2 ]; then
  echo "Test log tail:"
  tail -80 "$LOG" || true
  exit 1
fi

exit 0
