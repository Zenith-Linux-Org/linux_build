#!/bin/bash
set -e
ROOT="$1"
SRC="$ROOT/build/toolchains/pkgconf/pkgconf-3.0.7"
BUILD="$ROOT/out/build/toolchain-pkgconf"
PREFIX="$ROOT/out/host"

if [ -x "$PREFIX/bin/pkgconf" ] || [ -x "$PREFIX/bin/pkg-config" ]; then
    echo "pkgconf: already built, skipping"
    exit 0
fi

mkdir -p "$BUILD"
CC="clang -static" CFLAGS="-O2" meson setup "$BUILD" "$SRC" \
    --prefix="$PREFIX" \
    --default-library=static \
    2>/dev/null || \
CC="clang -static" CFLAGS="-O2" meson setup "$BUILD" "$SRC" \
    --prefix="$PREFIX" \
    --default-library=static
ninja -C "$BUILD"
ninja -C "$BUILD" install
echo "pkgconf: installed to $PREFIX/bin/pkgconf"
