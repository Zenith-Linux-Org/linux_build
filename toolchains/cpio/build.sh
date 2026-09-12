#!/bin/bash
set -e
ROOT="$1"
SRC="$ROOT/build/toolchains/cpio/cpio-2.15"
BUILD="$ROOT/out/build/toolchain-cpio"
PREFIX="$ROOT/out/host"

if [ -x "$PREFIX/bin/cpio" ]; then
    echo "cpio: already built, skipping"
    exit 0
fi

mkdir -p "$BUILD"
cd "$BUILD"
CC=clang CFLAGS="-O2" LDFLAGS="-static" "$SRC/configure" --prefix="$PREFIX" --disable-shared --enable-static
make -j"$(nproc)"
make install
echo "cpio: installed to $PREFIX/bin/cpio"
