#!/bin/bash
set -e
ROOT="$1"
PKG_DIR="$2"
PREFIX="${ROOT}/out/target/usr"
BUILD_DIR="${ROOT}/out/build/zenith-agent"

export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export CFLAGS="${CFLAGS} -Wno-bitwise-op-parentheses -Wno-shift-op-parentheses"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
meson setup "$PKG_DIR" --prefix="$PREFIX" --cross-file "${ROOT}/build/musl-cross.txt" --wipe 2>/dev/null || \
meson setup "$PKG_DIR" --prefix="$PREFIX" --cross-file "${ROOT}/build/musl-cross.txt"
ninja
ninja install
