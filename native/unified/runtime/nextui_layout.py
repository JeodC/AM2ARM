"""Locate the installed Standard game and its portable stock saves."""
import json
import os
from pathlib import Path
from menu_entries import install_play_entry, write_text


def relative_game(card, game):
    card, game = Path(card).resolve(), Path(game).resolve()
    if card not in game.parents:
        raise RuntimeError('Choose a folder on the game card.')
    return game.relative_to(card)


def record(card):
    return Path(card)/'AM2ARM/state/installation.json'


def recorded_path(card, value):
    if not isinstance(value, str) or not value or Path(value).is_absolute():
        raise RuntimeError('The installation record must use a folder on the game card.')
    return card/relative_game(card, card/value)


def installed_game(card):
    path = record(card)
    if not path.is_file():
        raise RuntimeError('Open AM2ARM Autopatcher and install Standard first.')
    return recorded_path(card, json.loads(path.read_text())['game'])


def stock_save_directory(card, game):
    path = record(card)
    if path.is_file():
        state = json.loads(path.read_text())
        if state.get('stock_saves'):
            return recorded_path(card, state['stock_saves'])
        old = recorded_path(card, state['game'])/'state/config/AM2RStandardLinux'
        if old.is_dir():
            return old
    return game/'state/config/AM2RStandardLinux'


def write_play_entry(card, game):
    state = dict(game=relative_game(card, game).as_posix())
    # Keep a previous stock save directory when a new game is installed beside it.
    previous = record(card)
    if os.environ.get('AM2ARM_FRONTEND') == 'stock' or previous.is_file():
        old_save = stock_save_directory(card, game)
        if os.environ.get('AM2ARM_FRONTEND') == 'stock' or old_save.is_dir():
            state['stock_saves'] = relative_game(card, old_save).as_posix()
    install_play_entry(card, game)
    write_text(record(card), json.dumps(state, indent=2)+'\n')
