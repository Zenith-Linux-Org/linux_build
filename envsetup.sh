#!/bin/bash
# Zenith Linux Build Environment Setup
# Source this file to initialize the build environment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Add prebuilt toolchains to PATH
export PATH="$ROOT_DIR/prebuilts/toolchains/llvm/bin:$ROOT_DIR/prebuilts/tools/bin:$PATH"

# Build morning if not exists
MORNING_BIN="$ROOT_DIR/out/host/bin/morning"
MORNING_SRC="$ROOT_DIR/build/toolchains/morning/morning.c"
if [ ! -x "$MORNING_BIN" ]; then
    echo "Building morning..."
    mkdir -p "$(dirname "$MORNING_BIN")"
    # Try meson first, fall back to direct cc
    if meson --version &>/dev/null; then
        MORNING_BUILD="$ROOT_DIR/out/build/morning"
        mkdir -p "$MORNING_BUILD"
        meson setup "$MORNING_BUILD" "$ROOT_DIR/build/toolchains/morning" --prefix="$ROOT_DIR/out/host" 2>/dev/null && \
        ninja -C "$MORNING_BUILD" install
    fi
    # Fallback: direct cc build
    if [ ! -x "$MORNING_BIN" ]; then
        cc -std=c23 -Wall -Wextra -Werror -o "$MORNING_BIN" "$MORNING_SRC"
    fi
    echo "morning built to $MORNING_BIN"
fi
export PATH="$(dirname "$MORNING_BIN"):$PATH"

# Export mz build function
mz() {
    local target="${1:-iso_img}"
    ninja -f "$ROOT_DIR/out/build.ninja" -j$(nproc) "$target"
}
export -f mz

echo "Zenith Linux build environment loaded."
echo "  Use 'morning select <target>' to configure device."
echo "  Use 'mz [target]' to build."
