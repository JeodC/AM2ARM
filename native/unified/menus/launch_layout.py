"""Build firmware menu shortcuts around a single native AM2ARM payload."""
import json
from pathlib import Path
from menu_entries import config, write_text

APP = 'am2arm-launcher'
PLAY = 'AM2ARM.sh'
EDITIONS = 'AM2ARM Editions.sh'


def card_shortcuts(stage):
    entries = {}
    def add(name, content, mode=0o644):
        path = stage/name
        write_text(path, content, mode)
        entries[name] = path

    for frontend, locations in {
        'ports': ['ports/'+PLAY, 'roms/ports/'+PLAY,'ports/'+EDITIONS,'roms/ports/'+EDITIONS],
        'nextui': ['Tools/tg5040/AM2ARM.pak/launch.sh', 'Tools/tg5050/AM2ARM.pak/launch.sh'],
        'tools': ['Tools/my355/AM2ARM.pak/launch.sh'],
        'stock': ['Apps/AM2ARM/launch.sh'], 'spruce': ['App/AM2ARM/launch.sh'],
    }.items():
        for location in locations:
            mode = 'auto --setup' if location.endswith('/'+EDITIONS) else 'auto'
            # ROCKNIX can expose just a card's roms/ subtree in the menu. The
            # same shortcut inode identifies its backing card on a bind mount.
            backing_card = '''if [ "$card" = / ]; then
    case "$here" in
        */roms/ports)
            for volume in "${here%/roms/ports}"/games-*; do
                if [ -f "$volume/am2arm-launcher/launch.sh" ] &&
                   [ "$0" -ef "$volume/roms/ports/${0##*/}" ]; then
                    card=$volume
                    break
                fi
            done
            ;;
    esac
fi
''' if frontend == 'ports' else ''
            entry = f'''#!/bin/sh
set -eu
here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
card=$here
while [ "$card" != / ] && [ ! -f "$card/{APP}/launch.sh" ]; do card=$(dirname -- "$card"); done
{backing_card}if [ ! -f "$card/{APP}/launch.sh" ]; then
    echo 'The am2arm-launcher folder is missing. Extract the entire ZIP into the game library.' >&2
    exit 1
fi
export AM2ARM_FRONTEND={frontend} AM2ARM_GAME_CARD="$card" AM2ARM_PORTS_DIR="$here"
export AM2ARM_FETCH_DISPLAY=1
exec /bin/sh "$card/{APP}/launch.sh" {mode} "$@"
'''
            add(location,entry,0o755)
            if frontend in ('stock','spruce'):
                info = config('game')
                icon = '../../'+APP+'/AM2ARM/patcher/assets/app-icon.png'
                info.update(label='AM2ARM', icon=icon, icontop=icon,
                            description='Install and play AM2ARM')
                add(str(Path(location).with_name('config.json')),json.dumps(info,indent=2)+'\n')
    return entries
