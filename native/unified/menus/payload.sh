#!/bin/sh
set -eu
base=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# Some card transfer tools discard the executable bits recorded in the ZIP.
while IFS= read -r item; do
    case "$item" in *..*|/*|'') exit 1 ;; AM2ARM/*) ;; *) exit 1 ;; esac
    file="$base/$item"
    if [ ! -x "$file" ]; then
        if [ ! -f "$file" ] || ! chmod u+x "$file" || [ ! -x "$file" ]; then
            echo 'AM2ARM could not start a bundled program. Check the game card permissions.' >&2
            exit 1
        fi
    fi
done < "$base/executables.txt"
exec /bin/sh "$base/AM2ARM/launch.sh" "$@"
