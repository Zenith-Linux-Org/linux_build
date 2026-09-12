#!/bin/bash
set -e
ROOT="$1"
SRC="$ROOT/build/toolchains/gzip/gzip-1.14"
BUILD="$ROOT/out/build/toolchain-gzip"
PREFIX="$ROOT/out/host"

if [ -x "$PREFIX/bin/gzip" ]; then
    echo "gzip: already built, skipping"
    exit 0
fi

mkdir -p "$BUILD"
cd "$BUILD"
CC=clang CFLAGS="-O2" LDFLAGS="-static" "$SRC/configure" --prefix="$PREFIX" --disable-shared --enable-static
make -j"$(nproc)"
make install
echo "gzip: installed to $PREFIX/bin/gzip"
