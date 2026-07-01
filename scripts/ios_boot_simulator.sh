#!/usr/bin/env bash
# Boot the best available iOS simulator for App Store screenshots.
# Usage: ios_boot_simulator.sh <iphone|ipad-13>
set -euo pipefail

KIND="${1:?kind required: iphone or ipad-13}"

sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
xcrun simctl list devices available || true

eval "$(python3 <<PY
import json, subprocess, sys

kind = "${KIND}"

def score_iphone(name: str) -> int:
    n = name.lower()
    if "pro max" in n:
        return 100
    if "plus" in n:
        return 90
    if " pro" in n or n.endswith(" pro"):
        return 80
    if "mini" in n or "se" in n:
        return 20
    return 50

def score_ipad_13(name: str) -> int:
    n = name.lower()
    if "13-inch" in n or "13 inch" in n:
        return 100
    if "12.9" in n:
        return 90
    if "pro" in n:
        return 70
    if "air" in n:
        return 40
    if "mini" in n:
        return 20
    return 50

def collect(kind: str, available_only: bool):
    flag = ["available"] if available_only else []
    data = json.loads(
        subprocess.check_output(
            ["xcrun", "simctl", "list", "devices", *flag, "-j"],
            text=True,
        )
    )
    out = []
    for runtime in sorted(data["devices"].keys(), reverse=True):
        if "ios" not in runtime.lower():
            continue
        for device in data["devices"][runtime]:
            name = device.get("name", "")
            lower = name.lower()
            if kind == "iphone":
                if "iphone" not in lower:
                    continue
                score = score_iphone(name)
            else:
                if "ipad" not in lower:
                    continue
                score = score_ipad_13(name)
            if available_only and device.get("isAvailable") is False:
                continue
            out.append((score, runtime, name, device["udid"]))
    return out

candidates = collect(kind, True) or collect(kind, False)
if not candidates:
    subprocess.run(["xcrun", "simctl", "list", "devices"], check=False)
    raise SystemExit(f"No simulator found for kind={kind}")

candidates.sort(key=lambda x: (x[0], x[1]), reverse=True)
_, runtime, name, udid = candidates[0]
print(f"Selected: {name} ({udid}) on {runtime}", file=sys.stderr)
print(f"export DEVICE_ID={udid}")
print(f"export DEVICE_NAME='{name}'")
PY
)"

echo "DEVICE_ID=$DEVICE_ID" >> "${GITHUB_ENV:?GITHUB_ENV not set}"
echo "DEVICE_NAME=$DEVICE_NAME" >> "$GITHUB_ENV"
xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
xcrun simctl bootstatus "$DEVICE_ID" -b
open -a Simulator || true

if command -v flutter >/dev/null 2>&1; then
  flutter devices
fi

echo "Booted $DEVICE_NAME ($DEVICE_ID)"
