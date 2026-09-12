#!/usr/bin/env bash
set -euo pipefail

ROOT="$1"
SRC="$2"

echo "busybox: building static musl"

cd "$SRC"

# Unset ninja-injected CFLAGS/LDFLAGS to avoid conflicts with busybox's own flags
unset CFLAGS LDFLAGS

ROOTDIR="$ROOT"
EXTRA_CFLAGS="-I${ROOTDIR}/out/stubs -I${ROOTDIR}/kernel/linux/include/generated/uapi -I${ROOTDIR}/kernel/linux/include/uapi -include ${ROOTDIR}/out/stubs/linux/compiler.h -Wno-cpp"

# Seed config only if missing
if [ ! -f .config ]; then
  cp zenith_defconfig .config
  touch -r Makefile .config
fi

make -j"$(nproc)" \
  ARCH=x86_64 \
  HOSTCC=clang \
  CC="${ROOTDIR}/build/musl-clang" \
  AR=llvm-ar \
  STRIP=llvm-strip \
  EXTRA_CFLAGS="$EXTRA_CFLAGS" \
  EXTRA_LDFLAGS="-static" \
  2>&1 | tail -5

echo "busybox: installing to out/target"
make install \
  ARCH=x86_64 \
  HOSTCC=clang \
  CC="${ROOTDIR}/build/musl-clang" \
  AR=llvm-ar \
  STRIP=llvm-strip \
  EXTRA_CFLAGS="$EXTRA_CFLAGS" \
  EXTRA_LDFLAGS="-static" \
  CONFIG_PREFIX="${ROOTDIR}/out/target" \
  2>&1 | tail -5

echo "busybox: done"
