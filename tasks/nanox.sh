#!/bin/bash
set -e
ROOT="$1"
PKG_DIR="$2"
PREFIX="${ROOT}/out/target/usr"
BUILD_DIR="${ROOT}/out/build/nanox"

mkdir -p "$BUILD_DIR"
cd "${PKG_DIR}/src"
mkdir -p lib bin

make -j"$(nproc)" \
  CC="${CC:-clang}" \
  CFLAGS="-O2 -pipe -march=x86-64-v3 -fno-omit-frame-pointer -Wno-unused-parameter -Wno-unused-but-set-variable -Wno-unused-function -Wno-sign-compare -Wno-constant-conversion -Wno-pointer-sign -Wno-missing-field-initializers -Wno-cast-function-type-mismatch -Wno-cpp -Wno-misleading-indentation -D_GNU_SOURCE -include alloca.h" \
  LDFLAGS="${LDFLAGS}"
make install \
  INSTALL_PREFIX="${ROOT}/out/target/usr" \
  INSTALL_OWNER1="" \
  INSTALL_OWNER2=""
