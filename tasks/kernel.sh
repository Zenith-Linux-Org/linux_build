#!/bin/bash
# Linux kernel build wrapper for Zenith Linux
# Usage: kernel.sh <root> <tree_path> <config> <firmware_path> <image_type>
set -euo pipefail

ROOT="$1"
TREE_PATH="$2"
CONFIG="$3"
FIRMWARE_PATH="$4"
IMAGE_TYPE="$5"

KERNEL_DIR="$ROOT/$TREE_PATH"
SYSROOT="$ROOT/out/target"
mkdir -p "$SYSROOT/boot"

echo "kernel: building from $KERNEL_DIR with config $CONFIG"

cd "$KERNEL_DIR"
make -j$(nproc) "ARCH=x86_64" "CC=clang" "LD=ld.lld" "$CONFIG" 2>/dev/null || true
make -j$(nproc) "ARCH=x86_64" "CC=clang" "LD=ld.lld" "$IMAGE_TYPE"

cp "$KERNEL_DIR/arch/x86/boot/$IMAGE_TYPE" "$SYSROOT/boot/$IMAGE_TYPE"
echo "kernel: installed $IMAGE_TYPE to $SYSROOT/boot/"
