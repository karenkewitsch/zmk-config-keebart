#!/usr/bin/env bash
set -euo pipefail

ZMK_DIR="${ZMK_DIR:-$HOME/zmk}"
CONFIG_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="$CONFIG_DIR/firmware"
IMAGE="zmkfirmware/zmk-build-arm:stable"

# Initialize west workspace using local manifest (mirrors the GitHub Actions workflow)
if [ ! -f "$ZMK_DIR/.west/config" ]; then
  echo "Initializing ZMK workspace at $ZMK_DIR..."
  mkdir -p "$ZMK_DIR/config"
  cp "$CONFIG_DIR/config/west.yml" "$ZMK_DIR/config/west.yml"
  docker run --rm \
    -v "$ZMK_DIR":/zmk \
    -w /zmk \
    "$IMAGE" \
    sh -c "west init -l config && west update"
fi

mkdir -p "$OUTPUT_DIR"

build() {
  local board=$1
  local extra_args=${2:-}

  echo "Building $board..."
  docker run --rm \
    -v "$ZMK_DIR":/zmk \
    -v "$CONFIG_DIR":/zmk-config \
    -w /zmk/zmk/app \
    "$IMAGE" \
    sh -c "west zephyr-export && \
    west build -p -b $board -- \
      -DZMK_CONFIG=/zmk-config/config \
      -DZMK_EXTRA_MODULES=/zmk-config \
      -DSHIELD=nice_view \
      -DSNIPPET=studio-rpc-usb-uart \
      $extra_args && \
    cp build/zephyr/zmk.uf2 /zmk-config/firmware/${board}.uf2"

  echo "  -> firmware/${board}.uf2"
}

build corne_choc_pro_left "-DCONFIG_ZMK_STUDIO=y"
build corne_choc_pro_right

echo ""
echo "Done! Firmware files:"
ls -lh "$OUTPUT_DIR"/*.uf2
