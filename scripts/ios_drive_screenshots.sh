#!/usr/bin/env bash
# Run flutter drive with a prebuilt app; stop once screenshots exist (avoids post-test hang).
set -euo pipefail

DEVICE_ID="${1:?device udid required}"
APP_PATH="${2:?Runner.app path required}"
EMAIL="${3:-}"
PASSWORD="${4:-}"
LOG="${5:-flutter-drive.log}"
OUT_DIR="${6:-collected-screenshots}"

cd "$(dirname "$0")/../mobile"
mkdir -p "$OUT_DIR"
: > "$LOG"

echo "Starting flutter drive with prebuilt app..."
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_screenshots_test.dart \
  --use-application-binary="$APP_PATH" \
  -d "$DEVICE_ID" \
  --dart-define=SCREENSHOT_EMAIL="$EMAIL" \
  --dart-define=SCREENSHOT_PASSWORD="$PASSWORD" \
  >> "$LOG" 2>&1 &
DRIVE_PID=$!

screenshot_count() {
  find screenshots integration_test/screenshots build/integration_test "$OUT_DIR" \
    -name '*.png' 2>/dev/null | wc -l | tr -d ' '
}

echo "Waiting for screenshots (max ~11 min)..."
found=0
for i in $(seq 1 330); do
  count=$(screenshot_count)
  if [ "$count" -ge 3 ]; then
    echo "Found $count screenshot(s) after ~$((i * 2))s — stopping drive."
    found=1
    sleep 3
    break
  fi
  if ! kill -0 "$DRIVE_PID" 2>/dev/null; then
    echo "flutter drive exited after ~$((i * 2))s"
    break
  fi
  sleep 2
done

kill -INT "$DRIVE_PID" 2>/dev/null || true
sleep 2
kill -TERM "$DRIVE_PID" 2>/dev/null || true
wait "$DRIVE_PID" 2>/dev/null || true

count=$(screenshot_count)
echo "Total screenshots found: $count"
if [ "$count" -lt 1 ] && [ "$found" -eq 0 ]; then
  echo "Drive log tail:"
  tail -40 "$LOG" || true
  exit 1
fi

# Copy into output dir
find screenshots integration_test/screenshots build/integration_test -name '*.png' 2>/dev/null \
  | while read -r f; do cp -n "$f" "$OUT_DIR/" 2>/dev/null || cp "$f" "$OUT_DIR/"; done
