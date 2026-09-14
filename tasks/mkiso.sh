#!/bin/bash
# Usage: mkiso.sh <root> <sysroot>
# Builds bootable ISO with EROFS root filesystem + tiny initramfs init.
set -euo pipefail

ROOT="$1"
SYSROOT="$2"
ISO_DIR="$ROOT/out/iso"
ISO_OUT="$ROOT/out/images/zenith-x86_64.iso"
EROFS_IMG="$ROOT/out/images/rootfs.erofs"
INITRAMFS="$ROOT/out/images/initramfs.cpio.gz"

rm -rf "$ISO_DIR" "$EROFS_IMG" "$INITRAMFS"
mkdir -p "$ISO_DIR/boot/grub" "$ISO_DIR/boot" "$ROOT/out/images"

cp "$ROOT/kernel/linux/arch/x86/boot/bzImage" "$ISO_DIR/boot/bzImage"

# --- Build EROFS root image ---
EROFS_DIR="$ROOT/out/erofs-root"
rm -rf "$EROFS_DIR"
mkdir -p "$EROFS_DIR"/{bin,sbin,etc,proc,sys,dev,tmp,run,var/log,usr/bin,usr/lib,usr/libexec,usr/sbin,usr/share/models,lib}

# zenith-heart (PID 1)
for src in "$SYSROOT/bin/zenith-heart" "$ROOT/out/build/zenith-heart/zenith-heart"; do
    if [ -f "$src" ]; then
        cp "$src" "$EROFS_DIR/bin/zenith-heart"
        chmod 755 "$EROFS_DIR/bin/zenith-heart"
        break
    fi
done
[ -f "$EROFS_DIR/bin/zenith-heart" ] || { echo "mkiso: ERROR: zenith-heart not found"; exit 1; }

# fish shell
for f in fish fish_indent fish_key_reader; do
    [ -f "$SYSROOT/usr/bin/$f" ] && cp "$SYSROOT/usr/bin/$f" "$EROFS_DIR/bin/$f"
done

# zenith agent
for src in "$SYSROOT/usr/bin/zenith" "$ROOT/out/build/zenith-agent/zenith"; do
    if [ -f "$src" ]; then
        cp "$src" "$EROFS_DIR/bin/zenith"
        chmod 755 "$EROFS_DIR/bin/zenith"
        break
    fi
done

# llama-server
[ -f "$SYSROOT/usr/bin/llama-server" ] && cp "$SYSROOT/usr/bin/llama-server" "$EROFS_DIR/bin/llama-server"

# iwd + iwctl
[ -f "$SYSROOT/usr/libexec/iwd" ] && { cp "$SYSROOT/usr/libexec/iwd" "$EROFS_DIR/usr/libexec/iwd"; chmod 755 "$EROFS_DIR/usr/libexec/iwd"; }
[ -f "$SYSROOT/usr/bin/iwctl" ] && cp "$SYSROOT/usr/bin/iwctl" "$EROFS_DIR/bin/iwctl"

# alsa (musl dynamic, needs ld-musl)
[ -f "$SYSROOT/usr/bin/aserver" ] && cp "$SYSROOT/usr/bin/aserver" "$EROFS_DIR/usr/bin/aserver"
[ -f "$SYSROOT/usr/bin/iwmon" ] && cp "$SYSROOT/usr/bin/iwmon" "$EROFS_DIR/usr/bin/iwmon"

# musl dynamic linker
cp "$ROOT/out/build/musl/lib/libc.so" "$EROFS_DIR/lib/ld-musl-x86_64.so.1"
chmod 755 "$EROFS_DIR/lib/ld-musl-x86_64.so.1"

# busybox (for modprobe in initramfs and EROFS root)
[ -f "$SYSROOT/bin/busybox" ] && cp "$SYSROOT/bin/busybox" "$EROFS_DIR/bin/busybox"
for cmd in sh ls mount umount insmod modprobe mkdir cat cp; do
    ln -sf busybox "$EROFS_DIR/bin/$cmd"
done

# Kernel modules to EROFS root
KVER=$(cd "$ROOT/kernel/linux" && make -s ARCH=x86_64 CC=clang LD=ld kernelrelease 2>/dev/null || echo "")
if [ -n "$KVER" ] && [ -d "$SYSROOT/lib/modules/$KVER" ]; then
    mkdir -p "$EROFS_DIR/lib/modules/$KVER"
    cp -a "$SYSROOT/lib/modules/$KVER"/* "$EROFS_DIR/lib/modules/$KVER/" 2>/dev/null || true
    echo "mkiso: installed kernel modules ($KVER) to EROFS root"
else
    echo "mkiso: WARNING: kernel modules not found at $SYSROOT/lib/modules/$KVER"
fi

# Qwen model
if [ -f "$ROOT/prebuilts/models/qwen-1.7b.gguf" ]; then
    cp "$ROOT/prebuilts/models/qwen-1.7b.gguf" "$EROFS_DIR/usr/share/models/qwen-1.7b.gguf"
    echo "mkiso: included Qwen model ($(du -h "$ROOT/prebuilts/models/qwen-1.7b.gguf" | cut -f1))"
else
    echo "mkiso: WARNING: Qwen model not found at prebuilts/models/qwen-1.7b.gguf"
fi

# Build EROFS image (lz4hc compressed)
mkfs.erofs -z lz4hc -b 4096 "$EROFS_IMG" "$EROFS_DIR"
echo "mkiso: EROFS root size: $(du -h "$EROFS_IMG" | cut -f1)"
cp "$EROFS_IMG" "$ISO_DIR/boot/rootfs.erofs"

# --- Initramfs ---
# Contains: zenith-heart (PID 1), busybox (modprobe/insmod), kernel modules
INIT_DIR="$ROOT/out/initramfs"
rm -rf "$INIT_DIR"
mkdir -p "$INIT_DIR/bin" "$INIT_DIR/lib/modules"

# zenith-heart
for src in "$SYSROOT/bin/zenith-heart" "$ROOT/out/build/zenith-heart/zenith-heart"; do
    if [ -f "$src" ]; then
        cp "$src" "$INIT_DIR/bin/zenith-heart"
        chmod 755 "$INIT_DIR/bin/zenith-heart"
        break
    fi
done

# busybox (static musl, provides modprobe/insmod/sh)
[ -f "$SYSROOT/bin/busybox" ] && cp "$SYSROOT/bin/busybox" "$INIT_DIR/bin/busybox"
for cmd in sh ls mount umount insmod modprobe mkdir cat cp mknod sleep; do
    ln -sf busybox "$INIT_DIR/bin/$cmd"
done

# Kernel modules needed for boot (EROFS + loop + block drivers)
KVER=$(ls "$SYSROOT/lib/modules/" 2>/dev/null | head -1)
if [ -n "$KVER" ] && [ -d "$SYSROOT/lib/modules/$KVER" ]; then
    mkdir -p "$INIT_DIR/lib/modules/$KVER"
    # Copy entire module tree (preserves subdirs for modprobe)
    cp -a "$SYSROOT/lib/modules/$KVER"/* "$INIT_DIR/lib/modules/$KVER/" 2>/dev/null || true
    echo "mkiso: initramfs modules: $(find "$INIT_DIR/lib/modules/$KVER" -name "*.ko*" 2>/dev/null | wc -l) files"
fi

cd "$INIT_DIR"
/usr/bin/find . -print0 | cpio --null -ov --format=newc 2>/dev/null | gzip -9 > "$INITRAMFS"
cd "$ROOT"
echo "mkiso: initramfs size: $(du -h "$INITRAMFS" | cut -f1)"
cp "$INITRAMFS" "$ISO_DIR/boot/initramfs.cpio.gz"

# --- GRUB config ---
cat > "$ISO_DIR/boot/grub/grub.cfg" << 'GRUBEOF'
set timeout=3
set default=0

menuentry "Zenith Linux" {
    linux /boot/bzImage root=/dev/ram0 rw quiet rdinit=/bin/zenith-heart
    initrd /boot/initramfs.cpio.gz
}
GRUBEOF

# --- Build ISO ---
GRUBTMP="$ROOT/out/grubtmp"
mkdir -p "$GRUBTMP"
TMPDIR="$GRUBTMP" grub-mkrescue -o "$ISO_OUT" "$ISO_DIR" 2>&1
rm -rf "$GRUBTMP"
echo "mkiso: created $ISO_OUT ($(du -h "$ISO_OUT" | cut -f1))"
