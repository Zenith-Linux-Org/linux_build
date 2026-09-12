#!/bin/bash
set -e
ROOT="$1"
PKG_DIR="$2"
PREFIX="${ROOT}/out/target/usr"
BUILD_DIR="${ROOT}/out/build/alsa"

if [ -f "${PREFIX}/lib/libasound.a" ]; then
  echo "alsa: already built, skipping"
  exit 0
fi

mkdir -p "$BUILD_DIR"

if [ ! -f "${PKG_DIR}/configure" ]; then
  cd "$PKG_DIR"
  autoreconf -fi
fi

cd "$BUILD_DIR"
"${PKG_DIR}/configure" \
  --prefix="$PREFIX" \
  --libdir="$PREFIX/lib" \
  CC="${CC:-clang}" \
  CFLAGS="-O2 -pipe -march=x86-64-v3 -fno-omit-frame-pointer -std=gnu23 -D__user= -D__kernel= -D__force= -Wno-unused-parameter" \
  CCASFLAGS="-O2 -pipe -march=x86-64-v3 -fno-omit-frame-pointer -std=gnu23" \
  LDFLAGS="${LDFLAGS}"
make -j"$(nproc)"
make install
