#!/bin/bash
set -e
ROOT="$1"
PKG_DIR="$2"
PREFIX="${ROOT}/out/target/usr"
BUILD_DIR="${ROOT}/out/build/musl"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
"${PKG_DIR}/configure" \
  --prefix="$PREFIX" \
  --libdir="$PREFIX/lib" \
  CC="${CC:-clang}" \
  CFLAGS="${CFLAGS:--O2}"
make -j"$(nproc)"
make install
