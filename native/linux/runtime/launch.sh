#!/bin/sh
set -eu
cd "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
ulimit -c 0
ulimit -f 262144
mkdir -p state
exec python3 runtime/launch.py > state/launcher.log 2>&1
