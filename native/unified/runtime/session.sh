#!/bin/sh
# route.py passes the resolved display environment to this whole session.
set -eu
rt=${AM2ARM_RUNTIME_DIR:?}
app=$(dirname -- "$rt")
card=${SDCARD_PATH:?}
frontend=${AM2ARM_FRONTEND:?}
backend=${AM2ARM_DISPLAY_PATH:?}
mode=$1
shift
loader="$rt/core/ld-linux-aarch64.so.1"
libs="$rt/core:$rt/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
printf 'Display path: %s\n' "$backend"
case "$backend" in
    ports) ;;
    direct)
        case "$frontend" in
            spruce|ports|tools)
                case "${AM2ARM_DEVICE_PROFILE:-}" in
                    g350|rg351p)
                        # AmberELEC keeps its Pulse session in the firmware home.
                        # Resolve it before redirecting GameMaker's saves to the card.
                        if [ -z "${PULSE_SERVER:-}" ]; then
                            server=$(LC_ALL=C timeout 3 pactl info 2>/dev/null | sed -n 's/^Server String: //p')
                            if [ -n "$server" ]; then export PULSE_SERVER="$server"; fi
                        fi
                        cookie="${XDG_CONFIG_HOME:-${HOME:-/storage}/.config}/pulse/cookie"
                        if [ -z "${PULSE_COOKIE:-}" ] && [ -r "$cookie" ]; then
                            export PULSE_COOKIE="$cookie"
                        fi
                        ;;
                esac
                portable_home="$app/state/home"
                if [ "$mode" = auto ]; then
                    portable_home="$card/AM2ARM-data/home"
                    for older in "$card/AM2ARM/state/home" "${AM2ARM_PORTS_DIR:-$card/ports}/AM2ARM/state/home"; do
                        if [ -d "$older/.config" ]; then portable_home=$older; break; fi
                    done
                fi
                export HOME="$portable_home"
                mkdir -p "$HOME"
                export XDG_CONFIG_HOME="$HOME/.config" XDG_DATA_HOME="$HOME/.local/share"
                ;;
        esac
        ;;
    *) exit 1 ;;
esac
bundled_python() {
    "$loader" --library-path "$libs" "$rt/python/usr/bin/python3.11" "$@"
}
if [ "$mode" = auto ] || [ "$mode" = game ]; then
    AM2ARM_SINGLE_SCREEN=$(bundled_python "$rt/first_run.py" screens "$backend")
    export AM2ARM_SINGLE_SCREEN
fi
if [ "$mode" = auto ]; then
    export AM2ARM_FIRST_RUN=1
    target=''
    if [ "${1:-}" = --setup ]; then
        shift
    else
        target=$(bundled_python "$rt/first_run.py" "$AM2ARM_SINGLE_SCREEN")
    fi
    if [ -z "$target" ]; then
        if [ "$backend" = ports ]; then
            /bin/sh "$app/patcher/launch.sh" || exit $?
        else
            bundled_python "$rt/nextui_session.py" patcher || exit $?
        fi
        target=$(bundled_python "$rt/first_run.py" "$AM2ARM_SINGLE_SCREEN")
        if [ -z "$target" ]; then echo 'No completed installation selected.'; exit 1; fi
    fi
    export AM2ARM_PLAY_DIR="$target"
    mode=game
fi
if [ "$backend" = direct ]; then
    status=0
    bundled_python "$rt/nextui_session.py" "$mode" || status=$?
    if [ "$mode" = game ] && [ "$status" -eq 78 ]; then
        export AM2ARM_DISPLAY_NOTICE=westonpack
        if [ "${AM2ARM_FETCH_DISPLAY:-}" = 1 ] && [ "${AM2ARM_FIRST_RUN:-}" = 1 ]; then
            bundled_python "$rt/nextui_session.py" patcher || exit $?
            unset AM2ARM_DISPLAY_NOTICE
            bundled_python "$rt/nextui_session.py" game
            exit $?
        fi
        bundled_python "$rt/nextui_session.py" patcher || :
    fi
    exit "$status"
elif [ "$mode" = game ]; then
    # The Ports game launcher uses the firmware's python3.
    unset PYTHONPATH PYTHONHOME
    exec /bin/sh "${AM2ARM_PLAY_DIR:-${AM2ARM_PORTS_DIR:?}/AM2ARM Standard}/launch.sh" "$@"
fi
exec /bin/sh "$app/patcher/launch.sh" --output "${AM2ARM_PORTS_DIR:-$card/ports}" "$@"
