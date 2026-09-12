#!/bin/bash
set -e
ROOT="$1"
SRC="$ROOT/build/toolchains/make/make-4.4.1"
BUILD="$ROOT/out/build/toolchain-make"
PREFIX="$ROOT/out/host"

if [ -x "$PREFIX/bin/make" ]; then
    echo "make: already built, skipping"
    exit 0
fi

mkdir -p "$BUILD"
cd "$BUILD"
CC=clang CFLAGS="-static -O2" "$SRC/configure" --prefix="$PREFIX" --disable-shared --enable-static --without-libintl-prefix --without-libintl-lib
make -j"$(nproc)"
make install
echo "make: installed to $PREFIX/bin/make"
