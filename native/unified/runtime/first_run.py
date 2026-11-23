"""Find a player's original and start a verified handheld installation."""
import fcntl
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import stat
import sys
import subprocess
import re
import tempfile
from zipfile import BadZipFile, ZipFile

from handheld_platform import active_sway_outputs
from linux_patcher import EDITIONS, prepare_game
from menu_entries import write_text
from nextui_layout import installed_game
from patch_core import PatchError, sha256_file


REQUIRED = {'edition.json', 'launch.sh', 'runtime/launch.py', 'data/runner', 'data/game.unx'}
EDITABLE = {'data/game.ini', 'data/options.ini', 'data/modifiers.ini', 'data/gamecontrollerdb.txt'}
HAPTICS = 'data/libAM2ARMHaptics.so'


def find_original(app, card, ports):
    """Read ZIP directories only. The patcher verifies the original bytes at install."""
    old_input = app/'patcher/input'
    roots = [old_input, card, card/'Downloads', card/'Download', ports, app,
             card/'AM2ARM/patcher/input', card/'am2arm-launcher/AM2ARM/patcher/input',
             ports/'am2arm-launcher/AM2ARM/patcher/input']
    if card.name.lower() == 'roms' and card.parent != Path('/'):
        roots += [card.parent, card.parent/'Downloads']
    found = set()
    for folder in dict.fromkeys(roots):
        try:
            entries = list(folder.iterdir())
        except OSError:
            continue
        for path in entries:
            if path.suffix.lower() != '.zip' or (folder.name != 'input' and
                    not path.name.lower().startswith('am2r')):
                continue
            try:
                with ZipFile(path) as archive:
                    names = {n.lower() for n in archive.namelist()}
                if any(PurePosixPath(n).name == 'data.win' and
                       str(PurePosixPath(n).with_name('am2r.exe')) in names for n in names):
                    found.add(path.resolve())
            except (OSError, BadZipFile):
                continue
    return found.pop() if len(found) == 1 else None


def read_object(path):
    try:
        if not path.is_file():
            return {}
        value = json.loads(path.read_text())
        return value if isinstance(value, dict) else {}
    except (OSError, ValueError):
        return {}


def matches_edition(info, edition, version):
    return (info.get('product') == 'AM2ARM' and info.get('architecture') == 'aarch64'
            and info.get('version') == version
            and info.get('edition') == ('dual-screen' if edition == 'dual' else 'standard'))


def expected_files(manifest):
    entries = manifest.get('installed_files')
    if not isinstance(entries, dict) or not REQUIRED.issubset(entries):
        raise PatchError('Installation checksums are missing. Extract the complete AM2ARM installer again.')
    result = {}
    for name, entry in entries.items():
        path = PurePosixPath(name)
        if (not path.parts or path.is_absolute() or str(path) != name or '..' in path.parts
                or '\\' in name or ':' in name or not isinstance(entry, dict)
                or not isinstance(entry.get('size'), int) or entry['size'] < 0
                or not re.fullmatch('[a-f0-9]{64}', str(entry.get('sha256', '')))):
            raise PatchError('The installation checksum list is invalid. Extract the complete installer again.')
        # State, saved games and other files outside the shipped program are player-owned.
        if name in REQUIRED or name in ('README.txt', 'SAVE-TRANSFER.txt') or path.parts[0] in ('runtime', 'data'):
            result[name] = entry
    return result


def file_stamp(info):
    return [info.st_dev, info.st_ino, info.st_size, info.st_mtime_ns, info.st_ctime_ns]


def editable(name):
    return name in EDITABLE or name.startswith('data/mods/')


def matches_content(path, info, expected, alternate):
    if info.st_size != expected['size'] and not alternate:
        return False
    return (sha256_file(path) in (expected['sha256'], alternate)
            and file_stamp(path.lstat()) == file_stamp(info))


def inspect_files(game, entries, cached, haptics):
    damaged, verified = [], {}
    for name, expected in entries.items():
        path = game/name
        try:
            info = path.lstat()
            if stat.S_ISREG(info.st_mode):
                if editable(name):
                    continue
                stamp = file_stamp(info)
                alternate = haptics if name == HAPTICS else None
                if cached.get(name) == stamp or matches_content(path, info, expected, alternate):
                    verified[name] = stamp
                    continue
        except OSError:
            pass
        damaged.append(name)
    return damaged, verified


def repair_target(game, name):
    target = game/name
    if target.is_symlink() or (target.exists() and not target.is_file()):
        raise PatchError('A link or directory occupies a game file. Move it aside before repairing: ' + name)
    for parent in target.parents:
        if parent == game:
            break
        if parent.is_symlink() or (parent.exists() and not parent.is_dir()):
            raise PatchError('A link or file occupies a game directory. Move it aside before repairing: ' + str(parent))
    return target


class Library:
    def __init__(self, app, card, ports):
        self.app, self.card, self.ports = app, card, ports
        self.data = card/'AM2ARM-data'
        self.bundle = app/'patcher/patch-bundle'
        self.files, self.release, self.haptics = {}, {}, {}
        rumble = read_object(app/'runtime/rumble/library.json')
        for edition in EDITIONS:
            raw = (self.bundle/edition/'assembly.json').read_bytes()
            manifest = json.loads(raw)
            if edition == 'standard':
                self.version = manifest['version']
            elif manifest['version'] != self.version:
                raise PatchError('The bundled editions have different release versions.')
            self.files[edition] = expected_files(manifest)
            self.release[edition] = hashlib.sha256(raw).hexdigest()
            original = self.files[edition].get(HAPTICS, {}).get('sha256')
            self.haptics[edition] = rumble.get('brick') if original == rumble.get('original') else None
        if not isinstance(self.version, str) or not re.fullmatch(r'[0-9]+(?:[.][0-9]+)+', self.version):
            raise ValueError('Invalid version in the installation manifest.')
        self.output = self.data/'games'/self.version
        self.choice = self.data/'edition.txt'

    @classmethod
    def from_environment(cls):
        runtime = Path(os.environ['AM2ARM_RUNTIME_DIR']).resolve()
        card = Path(os.environ.get('AM2ARM_GAME_CARD') or runtime.parent.parent)
        ports = Path(os.environ.get('AM2ARM_PORTS_DIR') or card/'ports')
        return cls(runtime.parent, card, ports)

    def damaged(self, game, edition, full=False):
        location = hashlib.sha256(os.fsencode(game.resolve())).hexdigest()
        receipt = self.data/'verification'/self.version/f'{edition}-{location}.json'
        record = read_object(receipt)
        identity = [self.release[edition], self.haptics[edition]]
        previous = record.get('files', {}) if record.get('key') == identity else {}
        cached = previous if isinstance(previous, dict) and not full else {}
        damaged, stamps = inspect_files(game, self.files[edition], cached, self.haptics[edition])
        # Record successful hashes only. An explicit full check can invalidate a cached
        # file even when a card's coarse timestamps stayed unchanged.
        if stamps != previous or not previous:
            try:
                write_text(receipt, json.dumps({'key': identity, 'files': stamps}))
            except OSError:
                pass  # Verification still works when the cache cannot be written.
        return damaged

    def complete(self, game, edition, full=False):
        return (matches_edition(read_object(game/'edition.json'), edition, self.version)
                and not self.damaged(game, edition, full))

    def existing(self, edition, full=False):
        name = EDITIONS[edition]
        managed = self.output/name
        if os.path.lexists(managed):
            # A different installation can have independent saves for the same edition.
            return managed if self.complete(managed, edition, full) else None
        options = []
        if edition == 'standard':
            for root in dict.fromkeys((self.card, self.app.parent, self.ports)):
                try:
                    options.append(installed_game(root))
                except (OSError, KeyError, ValueError, RuntimeError, TypeError):
                    pass
        options.extend((self.ports/name, self.app.parent/name, self.card/'ports'/name,
                        self.card/'AM2ARM/games'/name))
        return next((game for game in dict.fromkeys(options) if self.complete(game, edition, full)), None)

    def selected(self, single):
        editions = ('standard',) if single else tuple(EDITIONS)
        try:
            choice = self.choice.read_text().strip()
        except OSError:
            choice = ''
        if choice in editions:
            previous = self.existing(choice)
            if previous or os.path.lexists(self.output/EDITIONS[choice]):
                return previous
        games = [game for edition in editions if (game := self.existing(edition))]
        return games[0] if len(games) == 1 else None

    def install(self, source, output, edition, progress):
        if edition not in EDITIONS or Path(output) != self.output:
            raise PatchError('Choose a supported edition for this game card.')
        if self.output.resolve() != self.card.resolve()/self.output.relative_to(self.card):
            raise PatchError('The generated game folder uses a link. Move it aside before installing.')
        self.data.mkdir(parents=True, exist_ok=True)
        with (self.data/'install.lock').open('a') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            if (os.environ.get('AM2ARM_FETCH_DISPLAY') == '1'
                    and os.environ.get('AM2ARM_DISPLAY_NOTICE') == 'westonpack'):
                from weston_graphics import prepare_graphics
                prepare_graphics(self.card, self.app/'runtime', os.environ, progress)
            progress(0, 1, 'Checking installed files…')
            game = self.existing(edition, full=True)
            digest = None
            if game is None:
                if source is None or not Path(source).is_file():
                    raise PatchError('Choose your original AM2R 1.1 ZIP to install or repair this edition.')
                game = self.output/EDITIONS[edition]
                if os.path.lexists(game) or os.path.lexists(game.with_name(game.name+'.sh')):
                    digest = self.repair(game, source, edition, progress)
                else:
                    game, digest = prepare_game(source, self.output, edition, progress, self.bundle)
                if not self.complete(game, edition):
                    raise PatchError('The installed files failed verification. Check the card and try again.')
            write_text(self.choice, edition+'\n')
            return game, digest

    def repair(self, game, source, edition, progress):
        if game.is_symlink() or (game.exists() and not game.is_dir()):
            raise PatchError('The generated game folder is a link or a file. Move it aside before repairing.')
        old = read_object(game/'edition.json')
        if old.get('version') and not matches_edition(old, edition, self.version):
            raise PatchError('A different edition occupies this game folder. Move it aside to keep it before installing.')
        missing_game = not game.exists()
        if not missing_game:
            damaged = self.damaged(game, edition)
            for name in damaged:
                repair_target(game, name)
        # Build and check the entire replacement before changing the installed program.
        # Each rename repairs one file atomically. An interrupted repair can be retried.
        with tempfile.TemporaryDirectory(prefix='.am2arm-repair-', dir=self.output) as folder:
            ready, digest = prepare_game(source, Path(folder), edition, progress, self.bundle)
            invalid, _ = inspect_files(ready, self.files[edition], {}, self.haptics[edition])
            if invalid or not matches_edition(read_object(ready/'edition.json'), edition, self.version):
                raise PatchError('The rebuilt files failed verification. Check the installer and try again.')
            if missing_game:
                # An interrupted install may leave its sibling Ports shortcut behind.
                if os.path.lexists(game):
                    raise PatchError('A game folder appeared during installation. Open AM2ARM again.')
                ready.rename(game)
            else:
                for name in damaged:
                    target = repair_target(game, name)
                    if editable(name) and target.exists():
                        continue
                    target.parent.mkdir(parents=True, exist_ok=True)
                    (ready/name).replace(target)
        return digest


def single_screen(backend):
    if backend == 'direct':
        return True
    try:
        model = Path('/proc/device-tree/model').read_bytes().lower()
    except OSError:
        model = b''
    if any(name in model for name in (b'rg ds', b'rg-ds', b'rgds')):
        return False
    if b'g350' in model:
        return True
    if os.environ.get('SWAYSOCK'):
        try:
            return len(active_sway_outputs(os.environ)) < 2
        except (OSError, ValueError, subprocess.SubprocessError):
            pass
    try:
        connected = [p for p in Path('/sys/class/drm').glob('card*-*/status')
                     if p.read_text().strip() == 'connected']
        return len(connected) == 1
    except OSError:
        return False


if __name__ == '__main__':
    if sys.argv[1] == 'screens':
        print(int(single_screen(sys.argv[2])))
    else:
        target = Library.from_environment().selected(single=sys.argv[1] == '1')
        if target:
            print(target)
