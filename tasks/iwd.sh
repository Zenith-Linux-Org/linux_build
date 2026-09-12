#!/bin/bash
set -e
ROOT="$1"
PKG_DIR="$2"
PREFIX="/usr"
BUILD_DIR="${ROOT}/out/build/iwd"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Create dummy man pages so build doesn't fail
for f in src/iwd.8 src/iwd.debug.7 src/iwd.config.5 src/iwd.network.5 src/iwd.ap.5 client/iwctl.1 monitor/iwmon.1 wired/ead.8 tools/hwsim.1; do
    mkdir -p "$(dirname "$f")" && touch "$f"
done

"${PKG_DIR}/configure" \
  --prefix="$PREFIX" \
  --libdir="$PREFIX/lib" \
  --enable-internal-ell \
  --disable-manual \
  --disable-client \
  CC="${CC:-clang}" \
  CFLAGS="-O2 -pipe -march=x86-64-v3 -fno-omit-frame-pointer -std=gnu23 -D__user= -D__kernel= -D__force= -D__must_check= -Wno-unused-parameter -Wno-unused-but-set-variable -Wno-unused-function -Wno-missing-field-initializers -Wno-cpp -Wno-misleading-indentation" \
  LDFLAGS="${LDFLAGS}"
make -j"$(nproc)"
make install DESTDIR="${ROOT}/out/target"
