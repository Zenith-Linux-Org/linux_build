#!/bin/bash
# Usage: kernel.sh <root> <tree_path> <config> <firmware_path> <image_type>
set -euo pipefail

ROOT="$1"
TREE_PATH="$2"
CONFIG="$3"
FIRMWARE_PATH="$4"
IMAGE_TYPE="$5"

KERNEL_DIR="$ROOT/$TREE_PATH"
SYSROOT="$ROOT/out/target"
MODDIR="$SYSROOT/lib/modules"
mkdir -p "$SYSROOT/boot"

echo "kernel: building from $KERNEL_DIR with config $CONFIG"

cd "$KERNEL_DIR"

# Copy defconfig as starting point, then adapt to this kernel version
cp "arch/x86/configs/${CONFIG}" .config
make -j$(nproc) ARCH=x86_64 CC=clang LD=ld olddefconfig

make -j$(nproc) ARCH=x86_64 CC=clang LD=ld "$IMAGE_TYPE"
make -j$(nproc) ARCH=x86_64 CC=clang LD=ld modules

cp "$KERNEL_DIR/arch/x86/boot/$IMAGE_TYPE" "$SYSROOT/boot/$IMAGE_TYPE"
echo "kernel: installed $IMAGE_TYPE to $SYSROOT/boot/"

rm -rf "$MODDIR"
make -j$(nproc) ARCH=x86_64 CC=clang LD=ld modules_install INSTALL_MOD_PATH="$SYSROOT"
echo "kernel: installed modules to $SYSROOT/lib/modules/"

# Generate module dependencies for modprobe
if command -v depmod &>/dev/null; then
    depmod -a -b "$SYSROOT" "$(make -s ARCH=x86_64 CC=clang LD=ld kernelrelease)"
    echo "kernel: generated module dependencies"
fi

if [ -d "$ROOT/$FIRMWARE_PATH" ]; then
    mkdir -p "$SYSROOT/lib/firmware"
    cp -a "$ROOT/$FIRMWARE_PATH"/* "$SYSROOT/lib/firmware/" 2>/dev/null || true
    echo "kernel: installed firmware"
fi
