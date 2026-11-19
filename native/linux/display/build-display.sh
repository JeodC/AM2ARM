#!/bin/sh
set -eu
: "${SYSROOT:?Set SYSROOT to the Debian 12 ARM64 development sysroot}"
if [ "$#" -ne 1 ]; then
    printf '%s\n' 'Usage: SYSROOT=/path/to/sysroot sh build-display.sh OUTPUT.so' >&2
    exit 2
fi
source_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
compiler=${CC:-clang}
"$compiler" --target=aarch64-linux-gnu --sysroot="$SYSROOT"     --gcc-install-dir="$SYSROOT/usr/lib/gcc/aarch64-linux-gnu/12"     -fuse-ld=lld -I"$SYSROOT/usr/include/aarch64-linux-gnu"     -ffile-prefix-map="$source_dir"=display -O2 -fPIC -fvisibility=hidden     -shared "$source_dir/linux-display.c" -ldl -lm -o "$1"
llvm-strip --strip-unneeded "$1"
