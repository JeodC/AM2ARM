"""Register the same SD-card application in each firmware's game menu."""
import json
import os
from pathlib import Path
from tempfile import NamedTemporaryFile


MARKER = '# AM2ARM SD launcher'
PREVIOUS_MARKER = '# AM2ARM NextUI launcher v1'
MENU = {'ports':'Ports', 'stock':'Apps', 'spruce':'Apps', 'nextui':'Tools', 'tools':'Tools'}


def script(frontend, mode):
    return f'''#!/bin/sh
{MARKER}
set -eu
here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
export AM2ARM_FRONTEND={frontend} AM2ARM_MENU_NAME={MENU[frontend]} AM2ARM_PORTS_DIR="$here"
base=$here
while [ "$base" != / ]; do
    if [ -f "$base/AM2ARM/launch.sh" ]; then exec /bin/sh "$base/AM2ARM/launch.sh" {mode} "$@"; fi
    base=$(dirname -- "$base")
done
for base in "${{SDCARD_PATH:-/mnt/SDCARD}}" /mnt/SDCARD; do
    if [ -f "$base/AM2ARM/launch.sh" ]; then exec /bin/sh "$base/AM2ARM/launch.sh" {mode} "$@"; fi
done
echo 'Place the AM2ARM folder on the game card next to its menu folders.' >&2
exit 1
'''


def location(card, frontend, mode, ports=None):
    title = 'AM2ARM Autopatcher' if mode == 'patcher' else 'AM2ARM Standard'
    if frontend == 'ports':
        return ports/(title+'.sh')
    if frontend in ('nextui','tools'):
        board = 'tg5040' if frontend == 'nextui' else 'my355'
        return card/'Tools'/board/(title+'.pak')/'launch.sh'
    folder = 'App' if frontend == 'spruce' else 'Apps'
    return card/folder/title.replace(' ', '')/'launch.sh'


def config(mode):
    play = mode == 'game'
    icon = '../../AM2ARM/patcher/assets/app-icon.png'
    return dict(label='AM2ARM Standard' if play else 'AM2ARM Autopatcher', icon=icon,
                icontop=icon, launch='launch.sh', hideInSimpleMode=False,
                description='Gameplay on a single screen' if play else 'Install AM2ARM from your AM2R 1.1 ZIP',
                devices=['MIYOO_FLIP','SPRUCE_MIYOO_FLIP','TRIMUI_SMART_PRO','SPRUCE_TRIMUI_SMART_PRO',
                         'TRIMUI_SMART_PRO_S','SPRUCE_TRIMUI_SMART_PRO_S','TRIMUI_BRICK','SPRUCE_TRIMUI_BRICK'])


def write_text(path, text, mode=0o644):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = None
    try:
        with NamedTemporaryFile(mode='w', encoding='utf-8', dir=path.parent, delete=False) as stream:
            tmp = Path(stream.name)
            stream.write(text)
        tmp.chmod(mode)
        tmp.replace(path)
    finally:
        if tmp:
            tmp.unlink(missing_ok=True)


def write_entry(path, frontend, mode):
    if frontend in ('spruce', 'stock'):
        write_text(path.parent/'config.json', json.dumps(config(mode), indent=2)+'\n')
    write_text(path, script(frontend, mode), 0o755)


def stage_patcher_entries(card):
    for frontend in MENU:
        folders = (card/'ports', card/'Roms/ports') if frontend == 'ports' else (None,)
        for folder in folders:
            write_entry(location(card, frontend, 'patcher', folder), frontend, 'patcher')


def play_path(card, game=None):
    frontend = os.environ.get('AM2ARM_FRONTEND', 'nextui')
    ports = Path(os.environ.get('AM2ARM_PORTS_DIR') or card/'ports').resolve()
    path = location(card, frontend, 'game', ports)
    if card.resolve() not in path.resolve().parents:
        raise RuntimeError('The menu folder must be on this card.')
    if path.is_symlink() or (frontend in ('spruce', 'stock') and not path.exists() and (path.parent/'config.json').exists()):
        raise RuntimeError('A different launcher already uses this menu entry.')
    if path.exists():
        previous = path.read_text(encoding='utf-8')
        known = previous.startswith(('#!/bin/sh\n'+MARKER+'\n', '#!/bin/sh\n'+PREVIOUS_MARKER+'\n'))
        if not known and game and path == game.with_suffix('.sh'):
            from linux_patcher import ports_launcher_script
            known = previous == ports_launcher_script(game.name)
        if not known:
            raise RuntimeError('An existing game menu entry uses a different launcher.')
    return frontend, path


def install_play_entry(card, game):
    frontend, path = play_path(card, game)
    write_entry(path, frontend, 'game')
