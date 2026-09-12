#!/bin/bash
# Usage: mkiso.sh <root> <sysroot>
set -euo pipefail

ROOT="$1"
SYSROOT="$2"
ISO_DIR="$ROOT/out/iso"
ISO_OUT="$ROOT/out/images/zenith-x86_64.iso"
INITRAMFS="$ROOT/out/images/initramfs.cpio.gz"

rm -rf "$ISO_DIR" "$INITRAMFS"
mkdir -p "$ISO_DIR/boot/grub" "$ISO_DIR/boot" "$ROOT/out/images"

cp "$ROOT/kernel/linux/arch/x86/boot/bzImage" "$ISO_DIR/boot/bzImage"

INITRAMFS_DIR="$ROOT/out/initramfs"
rm -rf "$INITRAMFS_DIR"
mkdir -p "$INITRAMFS_DIR"/{bin,sbin,etc,proc,sys,dev,tmp,run,var/log,usr/bin,usr/lib,usr/libexec,usr/sbin,usr/share/models,lib}

# copy zenith-heart to /bin (PID 1) — static musl, zero deps
for src in "$SYSROOT/bin/zenith-heart" "$ROOT/out/build/zenith-heart/zenith-heart"; do
    if [ -f "$src" ]; then
        cp "$src" "$INITRAMFS_DIR/bin/zenith-heart"
        chmod 755 "$INITRAMFS_DIR/bin/zenith-heart"
        break
    fi
done

if [ ! -f "$INITRAMFS_DIR/bin/zenith-heart" ]; then
    echo "mkiso: ERROR: zenith-heart not found"
    exit 1
fi

if [ -f "$SYSROOT/usr/bin/fish" ]; then
    cp "$SYSROOT/usr/bin/fish" "$INITRAMFS_DIR/bin/fish"
fi

for src in "$SYSROOT/usr/bin/zenith" "$ROOT/out/build/zenith-agent/zenith"; do
    if [ -f "$src" ]; then
        cp "$src" "$INITRAMFS_DIR/bin/zenith"
        chmod 755 "$INITRAMFS_DIR/bin/zenith"
        break
    fi
done

for src in "$SYSROOT/usr/bin/llama-server"; do
    if [ -f "$src" ]; then
        cp "$src" "$INITRAMFS_DIR/bin/llama-server"
        chmod 755 "$INITRAMFS_DIR/bin/llama-server"
        break
    fi
done

if [ -f "$SYSROOT/usr/libexec/iwd" ]; then
    cp "$SYSROOT/usr/libexec/iwd" "$INITRAMFS_DIR/usr/libexec/iwd"
    chmod 755 "$INITRAMFS_DIR/usr/libexec/iwd"
fi

for src in "$SYSROOT/usr/bin/iwctl"; do
    if [ -f "$src" ]; then
        cp "$src" "$INITRAMFS_DIR/bin/iwctl"
        chmod 755 "$INITRAMFS_DIR/bin/iwctl"
        break
    fi
done

# copy Qwen model into initramfs
if [ -f "$ROOT/prebuilts/models/qwen-1.7b.gguf" ]; then
    cp "$ROOT/prebuilts/models/qwen-1.7b.gguf" "$INITRAMFS_DIR/usr/share/models/qwen-1.7b.gguf"
    echo "mkiso: included Qwen model ($(du -h "$ROOT/prebuilts/models/qwen-1.7b.gguf" | cut -f1))"
else
    echo "mkiso: WARNING: Qwen model not found at prebuilts/models/qwen-1.7b.gguf"
fi

# no shell init needed — zenith-heart is static musl, mounts proc/sys/dev itself
rm -f "$INITRAMFS_DIR/init"

# musl dynamic linker for aserver, iwmon, etc.
cp "$ROOT/out/build/musl/lib/libc.so" "$INITRAMFS_DIR/lib/ld-musl-x86_64.so.1"
chmod 755 "$INITRAMFS_DIR/lib/ld-musl-x86_64.so.1"

# copy aserver, iwmon (musl-dynamic) into initramfs
for src in "$SYSROOT/usr/bin/aserver" "$SYSROOT/usr/bin/iwmon"; do
    if [ -f "$src" ]; then
        cp "$src" "$INITRAMFS_DIR/usr/bin/$(basename "$src")"
        chmod 755 "$INITRAMFS_DIR/usr/bin/$(basename "$src")"
    fi
done

cd "$INITRAMFS_DIR"
find . -print0 | cpio --null -ov --format=newc 2>/dev/null | gzip -9 > "$INITRAMFS"
cd "$ROOT"

echo "mkiso: initramfs size: $(du -h "$INITRAMFS" | cut -f1)"

cp "$INITRAMFS" "$ISO_DIR/boot/initramfs.cpio.gz"

cat > "$ISO_DIR/boot/grub/grub.cfg" << 'GRUBEOF'
set timeout=3
set default=0

menuentry "Zenith Linux" {
    linux /boot/bzImage root=/dev/ram0 rw quiet rdinit=/bin/zenith-heart
    initrd /boot/initramfs.cpio.gz
}
GRUBEOF

# build ISO — use project tmpdir to avoid filling /tmp
GRUBTMP="$ROOT/out/grubtmp"
mkdir -p "$GRUBTMP"
TMPDIR="$GRUBTMP" grub-mkrescue -o "$ISO_OUT" "$ISO_DIR" 2>&1
rm -rf "$GRUBTMP"
echo "mkiso: created $ISO_OUT ($(du -h "$ISO_OUT" | cut -f1))"
