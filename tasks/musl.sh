#!/bin/bash
# musl uses C99 internally — its source relies on C99 semantics (e.g. empty
# parameter lists meaning "unspecified args" vs C23 "zero args"). Project-wide
# -std=c23 does NOT apply to musl. We intentionally omit -std here and let
# musl's own configure/Makefile pick C99.
set -e
ROOT="$1"
PKG_DIR="$2"
PREFIX="${ROOT}/out/target/usr"
BUILD_DIR="${ROOT}/out/build/musl"
CLANG="${ROOT}/prebuilts/toolchains/llvm/bin/clang"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
"${PKG_DIR}/configure" \
  --prefix="$PREFIX" \
  --libdir="$PREFIX/lib" \
  CC="$CLANG" \
  CFLAGS="-O2 -pipe -march=x86-64-v3 -fomit-frame-pointer"
make -j"$(nproc)"
make install

# Install musl-clang compatible CRT stubs and libgcc into sysroot.
CLANG_RT="${ROOT}/prebuilts/toolchains/llvm/lib/clang/23/lib/x86_64-unknown-linux-gnu"
# compiler-rt CRT start/end objects (clang substitutes these for gcc's crtbegin/crtend)
cp "$CLANG_RT/clang_rt.crtbegin.o" "$BUILD_DIR/lib/crtbeginT.o"
cp "$CLANG_RT/clang_rt.crtend.o" "$BUILD_DIR/lib/crtend.o"
cp "$CLANG_RT/clang_rt.crtbegin.o" "$BUILD_DIR/lib/crtbegin.o"
cp "$CLANG_RT/clang_rt.crtend.o" "$BUILD_DIR/lib/crtendS.o"

# compiler-rt builtins replace libgcc
cp "$CLANG_RT/libclang_rt.builtins.a" "$BUILD_DIR/lib/libgcc.a"
cp "$CLANG_RT/libclang_rt.builtins.a" "$BUILD_DIR/lib/libgcc_eh.a"
cp "$CLANG_RT/libclang_rt.builtins.a" "$BUILD_DIR/lib/libgcc_s.a"

# libc++ static archive + ABI library for C++ packages (fish, llama-cpp, etc.)
LLVM_LIB="${ROOT}/prebuilts/toolchains/llvm/lib/x86_64-unknown-linux-gnu"
cp "$LLVM_LIB/libc++.a" "$BUILD_DIR/lib/libstdc++.a"
cp "$LLVM_LIB/libc++abi.a" "$BUILD_DIR/lib/libc++abi.a"

# musl-specific libc++ config — sets _LIBCPP_HAS_MUSL_LIBC=1 and hardening mode
CONFIG_DIR="$BUILD_DIR/libc++-config/x86_64-unknown-linux-musl/c++/v1"
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_DIR/__config_site" << 'ENDCONFIG'
#ifndef _LIBCPP___CONFIG_SITE
#define _LIBCPP___CONFIG_SITE
#define _LIBCPP_ABI_VERSION 1
#define _LIBCPP_ABI_NAMESPACE __1
#define _LIBCPP_HAS_THREADS 1
#define _LIBCPP_HAS_MONOTONIC_CLOCK 1
#define _LIBCPP_HAS_MUSL_LIBC 1
#define _LIBCPP_HAS_THREAD_API_PTHREAD 1
#define _LIBCPP_HAS_FILESYSTEM 1
#define _LIBCPP_HAS_RANDOM_DEVICE 1
#define _LIBCPP_HAS_LOCALIZATION 1
#define _LIBCPP_HAS_UNICODE 1
#define _LIBCPP_HAS_WIDE_CHARACTERS 1
#define _LIBCPP_HAS_TIME_ZONE_DATABASE 1
#define _LIBCPP_HARDENING_MODE_DEFAULT 2
#define _LIBCPP_ASSERTION_SEMANTIC_DEFAULT 2
#define _LIBCPP_LIBC_PICOLIBC 0
#define _LIBCPP_LIBC_NEWLIB 0
#define _LIBCPP_LIBC_LLVM_LIBC 0
#endif
ENDCONFIG

# Symlink into LLVM headers so #include <__config> finds it
ln -sf "$CONFIG_DIR/__config_site" \
  "${ROOT}/prebuilts/toolchains/llvm/include/c++/v1/__config_site"
