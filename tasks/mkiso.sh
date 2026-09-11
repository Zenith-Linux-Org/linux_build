#!/bin/bash
# Bootable ISO packer for Zenith Linux
# Usage: mkiso.sh <root> <sysroot>
set -euo pipefail

ROOT="$1"
SYSROOT="$2"
ISO_DIR="$ROOT/out/iso"
ISO_OUT="$ROOT/out/images/zenith-x86_64.iso"

mkdir -p "$ISO_DIR/boot/grub" "$ROOT/out/images"

cat > "$ISO_DIR/boot/grub/grub.cfg" << 'GRUB'
set timeout=3
set default=0

menuentry "Zenith Linux" {
    linux /boot/bzImage root=/dev/sda1 rw console=ttyS0
    initrd /boot/initramfs.cpio.gz
}
GRUB

# copy kernel
cp "$SYSROOT/boot/bzImage" "$ISO_DIR/boot/" 2>/dev/null || echo "mkiso: WARNING: bzImage not found"

# create ISO (needs xorriso or mkisofs)
if command -v xorriso &>/dev/null; then
    xorriso -as mkisofs -o "$ISO_OUT" -b boot/grub/grub.cfg \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        "$ISO_DIR"
    echo "mkiso: created $ISO_OUT"
elif command -v mkisofs &>/dev/null; then
    mkisofs -o "$ISO_OUT" -b boot/grub/grub.cfg \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        "$ISO_DIR"
    echo "mkiso: created $ISO_OUT"
else
    echo "mkiso: WARNING: no xorriso or mkisofs found, skipping ISO creation"
    echo "mkiso: ISO contents staged at $ISO_DIR"
fi
