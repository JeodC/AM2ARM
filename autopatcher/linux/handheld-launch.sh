#!/bin/sh
set -eu
cd "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
ulimit -c 0
mkdir -p state/tmp
am2arm_runtime=${AM2ARM_RUNTIME_DIR:-"$PWD/runtime"}
export PYTHONHOME="$am2arm_runtime/python/usr"
export PYTHONNOUSERSITE=1
export PYTHONDONTWRITEBYTECODE=1
export TCL_LIBRARY="$PYTHONHOME/share/tcltk/tcl8.6"
export TK_LIBRARY="$PYTHONHOME/share/tcltk/tk8.6"
export TMPDIR="$PWD/state/tmp"
sh "$PWD/compatibility-check.sh" >"$PWD/state/compatibility.log" 2>&1 || exit 1
exec /lib/ld-linux-aarch64.so.1 --library-path "$am2arm_runtime/lib" "$PYTHONHOME/bin/python3.11" "$PWD/handheld_launch.py" "$@" > state/launcher.log 2>&1
