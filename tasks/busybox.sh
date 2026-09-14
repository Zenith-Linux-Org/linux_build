#!/usr/bin/env bash
set -euo pipefail

ROOT="$1"
SRC="$2"

echo "busybox: building static musl"

cd "$SRC"

unset CFLAGS LDFLAGS

ROOTDIR="$ROOT"

# Create kernel header stubs if missing
if [ ! -f "${ROOTDIR}/out/stubs/linux/compiler.h" ]; then
    mkdir -p "${ROOTDIR}/out/stubs/linux"
    cat > "${ROOTDIR}/out/stubs/linux/compiler.h" << 'STUBEOF'
#ifndef _LINUX_COMPILER_H
#define _LINUX_COMPILER_H
#ifndef __user
#define __user
#endif
#ifndef __force
#define __force
#endif
#ifndef __bitwise
#define __bitwise
#endif
#ifndef __attribute_const__
#define __attribute_const__
#endif
#endif
STUBEOF
fi

EXTRA_CFLAGS="-I${ROOTDIR}/out/stubs -I${ROOTDIR}/kernel/linux/include/generated/uapi -I${ROOTDIR}/kernel/linux/include/uapi -include ${ROOTDIR}/out/stubs/linux/compiler.h -Wno-cpp"

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
    EXTRA_LDFLAGS="-static"

echo "busybox: installing to out/target"
make install \
    ARCH=x86_64 \
    HOSTCC=clang \
    CC="${ROOTDIR}/build/musl-clang" \
    AR=llvm-ar \
    STRIP=llvm-strip \
    EXTRA_CFLAGS="$EXTRA_CFLAGS" \
    EXTRA_LDFLAGS="-static" \
    CONFIG_PREFIX="${ROOTDIR}/out/target"

echo "busybox: done"
