#!/bin/bash
set -e
ROOT="$1"
PKG_DIR="$2"
PREFIX="${ROOT}/out/target/usr"
BUILD_DIR="${ROOT}/out/build/fish"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
cmake "$PKG_DIR" \
  -DCMAKE_C_COMPILER="${CC:-clang}" \
  -DCMAKE_CXX_COMPILER="${CXX:-clang++}" \
  -DCMAKE_C_FLAGS="${CFLAGS:--O2}" \
  -DCMAKE_CXX_FLAGS="${CXXFLAGS:--O2}" \
  -DCMAKE_EXE_LINKER_FLAGS="${LDFLAGS}" \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_INSTALL_LIBDIR="$PREFIX/lib" \
  -DRust_CARGO_TARGET=x86_64-unknown-linux-musl
cmake --build . -j"$(nproc)"
cmake --install .
