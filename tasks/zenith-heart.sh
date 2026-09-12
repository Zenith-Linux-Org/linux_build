#!/bin/bash
set -e
ROOT="$1"
PKG_DIR="$2"
MUSL_SRC="$ROOT/packages/system/musl"
MUSL_BUILD="$ROOT/out/build/musl"
OUT_DIR="$ROOT/out/target/bin"
mkdir -p "$OUT_DIR"

if [ ! -f "$MUSL_BUILD/lib/libc.a" ]; then
    echo "zenith-heart: building musl first..."
    mkdir -p "$MUSL_BUILD"
    cd "$MUSL_BUILD"
    bash "$MUSL_SRC/configure" --prefix=/usr CC=clang
    make -j"$(nproc)"
    cd "$ROOT"
fi

echo "zenith-heart: compiling static against musl"
clang -std=c23 -O2 -pipe -march=x86-64-v3 -Wall -Wextra -Werror -Wno-cpp \
    -nostdinc \
    -isystem "$MUSL_SRC/arch/x86_64" \
    -isystem "$MUSL_SRC/arch/generic" \
    -isystem "$MUSL_BUILD/obj/include" \
    -isystem "$MUSL_SRC/src/include" \
    -isystem "$MUSL_SRC/include" \
    -isystem "$ROOT/kernel/linux/include/uapi" \
    -isystem "$ROOT/kernel/linux/arch/x86/include/generated/uapi" \
    -isystem "$ROOT/kernel/linux/arch/x86/include/uapi" \
    -D_XOPEN_SOURCE=700 \
    -c "$PKG_DIR/zenith-heart.c" \
    -o "$ROOT/out/build/zenith-heart.o"

mkdir -p "$ROOT/out/build"
clang -static -nostdlib \
    "$MUSL_BUILD/lib/crt1.o" \
    "$MUSL_BUILD/lib/crti.o" \
    "$ROOT/out/build/zenith-heart.o" \
    "$MUSL_BUILD/lib/libc.a" \
    "$MUSL_BUILD/lib/crtn.o" \
    -o "$OUT_DIR/zenith-heart"

chmod 755 "$OUT_DIR/zenith-heart"
echo "zenith-heart: done → $OUT_DIR/zenith-heart"
readelf -h "$OUT_DIR/zenith-heart" | grep Type
ldd "$OUT_DIR/zenith-heart" 2>&1 || echo "zenith-heart: statically linked (no deps)"
