"""Install Standard and add its entry to the active firmware menu."""
from pathlib import Path
import os
from linux_patcher import prepare_game as prepare_standard
from nextui_layout import relative_game, write_play_entry
from menu_entries import play_path


def prepare_game(source, output, edition, progress):
    if edition != 'standard':
        raise RuntimeError('This handheld uses Standard Edition.')
    card = Path(os.environ.get('SDCARD_PATH', '/mnt/SDCARD'))
    relative_game(card, Path(output)/'AM2ARM Standard')
    play_path(card)
    result, digest = prepare_standard(source, output, edition, progress)
    write_play_entry(card, result)
    with (card/'AM2ARM/logs/compatibility.txt').open('a') as report:
        print('Standard installation verified. SHA-256:', digest, file=report)
    return result, digest
