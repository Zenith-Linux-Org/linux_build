#!/bin/bash
set -e
ROOT="$1"
PKG_DIR="$2"
PREFIX="${ROOT}/out/target/usr"
BUILD_DIR="${ROOT}/out/build/llama-cpp"
MUSL_LIB="${ROOT}/out/build/musl/lib"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
cmake "$PKG_DIR" \
  -DCMAKE_C_COMPILER="${CC:-clang}" \
  -DCMAKE_CXX_COMPILER="${CXX:-clang++}" \
  -DCMAKE_C_FLAGS="${CFLAGS:--O2}" \
  -DCMAKE_CXX_FLAGS="${CXXFLAGS:--O2}" \
  -DCMAKE_EXE_LINKER_FLAGS="${LDFLAGS} -L${MUSL_LIB} -lstdc++ -lc++abi -lunwind ${MUSL_LIB}/__cxa_thread_atexit_stub.o" \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_INSTALL_LIBDIR="$PREFIX/lib" \
  -DLLAMA_NATIVE=OFF \
  -DLLAMA_BUILD_TESTS=OFF \
  -DLLAMA_BUILD_EXAMPLES=OFF \
  -DLLAMA_BUILD_APP=OFF \
  -DLLAMA_CURL=OFF \
  -DLLAMA_OPENSSL=OFF \
  -DBUILD_SHARED_LIBS=OFF
cmake --build . -j"$(nproc)" --target llama-server
mkdir -p "$PREFIX/bin"
cp bin/llama-server "$PREFIX/bin/llama-server"
