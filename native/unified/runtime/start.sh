#!/bin/sh
set -eu
# All supported firmware shells implement the Linux core size limit.
# shellcheck disable=SC3045
ulimit -c 0
rt=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
app=$(dirname -- "$rt")
card=${AM2ARM_GAME_CARD:-$(dirname -- "$app")}
# Earlier NextUI game entries launch this script directly.
frontend=${AM2ARM_FRONTEND:-nextui}
mode=${1:-patcher}
if [ "$#" -gt 0 ]; then shift; fi
case "$mode" in auto|game|patcher) ;; *) exit 1 ;; esac
case "$frontend" in
    ports) menu=Ports ;;
    stock|spruce) menu=Apps ;;
    nextui|tools) menu=Tools ;;
    *) exit 1 ;;
esac
mkdir -p "$app/logs" "$app/patcher/input"
exec >> "$app/logs/compatibility.txt" 2>&1
printf '\nAM2ARM 1.6.3 | %s | %s | %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$frontend" "$mode"
if [ -r /proc/device-tree/model ]; then printf 'Board: '; tr '\000' ' ' < /proc/device-tree/model; printf '\n'; fi
case "$(uname -m)" in aarch64|arm64) ;; *) echo 'This release requires ARM64 Linux.'; exit 1 ;; esac
export SDCARD_PATH="$card" AM2ARM_FRONTEND="$frontend" AM2ARM_MENU_NAME="$menu"
export AM2ARM_INPUT_DIR="$app/patcher/input" AM2ARM_PATCH_ROOT="$app/patcher/patch-bundle" AM2ARM_RUNTIME_DIR="$rt"
export PYTHONPATH="$rt:$app/patcher" PYTHONHOME="$rt/python/usr" PYTHONNOUSERSITE=1 PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
loader="$rt/core/ld-linux-aarch64.so.1"
libs="$rt/core:$rt/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
if [ "$mode" = patcher ] && [ "${1:-}" = --cli ]; then
    shift
    exec "$loader" --library-path "$libs" "$rt/python/usr/bin/python3.11" "$app/patcher/linux_patcher.py" "$@"
fi
exec "$loader" --library-path "$libs" "$rt/python/usr/bin/python3.11" "$rt/route.py" \
    --exec /bin/sh "$rt/session.sh" "$mode" "$@"
