#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

export PATH="$ROOT_DIR/prebuilts/toolchains/llvm/bin:$ROOT_DIR/prebuilts/tools/bin:$PATH"

export TMPDIR="$ROOT_DIR/out/tmp"
mkdir -p "$TMPDIR"

# Install musl static coreutils (nproc, cp, etc.) if not present
if [ ! -x "$ROOT_DIR/out/host/bin/nproc" ]; then
    echo "Installing uutils coreutils (musl static)..."
    mkdir -p "$ROOT_DIR/out/host/bin"
    COREUTILS_URL="https://github.com/uutils/coreutils/releases/download/0.11.0/coreutils-0.11.0-x86_64-unknown-linux-musl.tar.gz"
    curl -sL --connect-timeout 30 --max-time 120 "$COREUTILS_URL" -o "$TMPDIR/coreutils.tar.gz"
    tar xzf "$TMPDIR/coreutils.tar.gz" -C "$TMPDIR"
    cp "$TMPDIR/coreutils-0.11.0-x86_64-unknown-linux-musl/coreutils" "$ROOT_DIR/out/host/bin/coreutils"
    chmod 755 "$ROOT_DIR/out/host/bin/coreutils"
    cd "$ROOT_DIR/out/host/bin"
    for cmd in nproc cp mv rm ln chmod chown mkdir cat echo ls head tail find sort uniq wc env date dd install touch chgrp comm csplit cut expand fmt fold join numfmt od paste pr ptx shuf split tac tee tr truncate unexpand uniq xargs; do
        ln -sf coreutils "$cmd" 2>/dev/null || true
    done
    rm -f "$TMPDIR/coreutils.tar.gz"
    rm -rf "$TMPDIR/coreutils-0.11.0-x86_64-unknown-linux-musl"
    echo "coreutils: installed to $ROOT_DIR/out/host/bin/"
fi
export PATH="$ROOT_DIR/out/host/bin:$PATH"

echo "Building host toolchains..."
for tool in make pkgconf cpio gzip; do
    bash "$ROOT_DIR/build/toolchains/$tool/build.sh" "$ROOT_DIR"
done

MORNING_BIN="$ROOT_DIR/out/host/bin/morning"
MORNING_SRC="$ROOT_DIR/build/toolchains/morning/morning.c"
if [ ! -x "$MORNING_BIN" ]; then
    echo "Building morning..."
    mkdir -p "$(dirname "$MORNING_BIN")"
    if meson --version &>/dev/null; then
        MORNING_BUILD="$ROOT_DIR/out/build/morning"
        mkdir -p "$MORNING_BUILD"
        meson setup "$MORNING_BUILD" "$ROOT_DIR/build/toolchains/morning" --prefix="$ROOT_DIR/out/host" 2>/dev/null && \
        ninja -C "$MORNING_BUILD" install
    fi
    if [ ! -x "$MORNING_BIN" ]; then
        cc -std=c23 -Wall -Wextra -Werror -o "$MORNING_BIN" "$MORNING_SRC"
    fi
    echo "morning built to $MORNING_BIN"
fi
export PATH="$(dirname "$MORNING_BIN"):$PATH"

mz() {
    local target="${1:-iso_img}"
    ninja -f "$ROOT_DIR/out/build.ninja" -j$(nproc) "$target"
}
export -f mz

echo "Zenith Linux build environment loaded."
echo "  Use 'morning select <target>' to configure device."
echo "  Use 'mz [target]' to build."
