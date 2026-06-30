#!/usr/bin/env bash
# Wait for Flutter to paint on iOS Simulator, then capture PNG via simctl.
set -euo pipefail

DEVICE_ID="${1:?device udid required}"
OUT_DIR="${2:-collected-screenshots}"
NAME="${3:-screenshot}"
LOG="${4:-flutter-run.log}"

mkdir -p "$OUT_DIR"

echo "Waiting for Flutter to start (log: $LOG)..."
ready=0
for _ in $(seq 1 120); do
  if grep -qE "Flutter run key commands|Debug service listening on|Syncing files to device|VM Service" "$LOG" 2>/dev/null; then
    ready=1
    break
  fi
  sleep 2
done

if [ "$ready" -ne 1 ]; then
  echo "Flutter did not report ready within 240s. Log tail:"
  tail -40 "$LOG" || true
  exit 1
fi

echo "Flutter process ready; waiting for first frame..."
sleep 25

osascript -e 'tell application "Simulator" to activate' 2>/dev/null || true
sleep 3

out="$OUT_DIR/${NAME}.png"
xcrun simctl io "$DEVICE_ID" screenshot "$out"

size=$(stat -f%z "$out" 2>/dev/null || stat -c%s "$out")
echo "Screenshot: $out ($size bytes)"

# Blank/white PNGs compress to roughly 10-20 KB; real UI is usually 200 KB+.
if [ "$size" -lt 80000 ]; then
  echo "Screenshot looks too small; waiting 30s and retrying..."
  sleep 30
  xcrun simctl io "$DEVICE_ID" screenshot "${OUT_DIR}/${NAME}-retry.png"
  size=$(stat -f%z "${OUT_DIR}/${NAME}-retry.png" 2>/dev/null || stat -c%s "${OUT_DIR}/${NAME}-retry.png")
  echo "Retry screenshot: ${size} bytes"
  if [ "$size" -lt 80000 ]; then
    echo "Screenshot still too small — UI may not have rendered."
    exit 1
  fi
fi
