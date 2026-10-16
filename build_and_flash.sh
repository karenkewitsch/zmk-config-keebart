#!/usr/bin/env bash
# Build firmware via build.sh, then flash left half, then right half (macOS).
# Usage: ./build_and_flash.sh [--skip-build]
set -euo pipefail

CONFIG_DIR="$(cd "$(dirname "$0")" && pwd)"
FIRMWARE_DIR="$CONFIG_DIR/firmware"

if [ "${1:-}" != "--skip-build" ]; then
  "$CONFIG_DIR/build.sh"
fi

# UF2 bootloader drives expose INFO_UF2.TXT at their root
find_uf2_volume() {
  local info
  for info in /Volumes/*/INFO_UF2.TXT; do
    [ -f "$info" ] && { dirname "$info"; return 0; }
  done
  return 1
}

flash() {
  local side=$1
  local uf2="$FIRMWARE_DIR/corne_choc_pro_${side}.uf2"
  local volume

  [ -f "$uf2" ] || { echo "Missing $uf2" >&2; exit 1; }

  echo ""
  echo "Plug in ${side} half and enter bootloader (double-tap reset)..."
  until volume=$(find_uf2_volume); do sleep 0.5; done
  echo "  found $volume, copying $(basename "$uf2")..."

  # -X skips xattrs (avoids macOS fcopyfile errors); device reboots mid-copy, so ignore exit code
  cp -X "$uf2" "$volume/" 2>/dev/null || true

  # Wait for the drive to unmount so the next half isn't flashed to the same volume
  while [ -d "$volume" ]; do sleep 0.5; done
  echo "  ${side} flashed"
}

flash left
flash right

echo ""
echo "Done! On macOS, re-pair via Bluetooth if HID config changed (e.g. pointing)."
