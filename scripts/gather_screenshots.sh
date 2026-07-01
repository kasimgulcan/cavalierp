#!/usr/bin/env bash
# Copy integration-test screenshots into one output folder.
set -euo pipefail

OUT="${1:?output directory required}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$OUT"

for dir in \
  "$ROOT/mobile/screenshots" \
  "$ROOT/mobile/integration_test/screenshots" \
  "$ROOT/mobile/build/integration_test"
do
  [ -d "$dir" ] || continue
  find "$dir" -maxdepth 4 -name '*.png' -print0 2>/dev/null \
    | while IFS= read -r -d '' f; do
        dest="$OUT/$(basename "$f")"
        [ "$f" -ef "$dest" ] && continue
        cp -f "$f" "$dest"
      done
done

count=$(find "$OUT" -maxdepth 1 -name '*.png' 2>/dev/null | wc -l | tr -d ' ')
echo "Gathered $count screenshot(s) in $OUT"
find "$OUT" -maxdepth 1 -name '*.png' -exec ls -la {} \; 2>/dev/null || true
