"""First launch from a firmware menu. Game installation remains manifest-verified."""
import fcntl
import hashlib
import os
from pathlib import Path, PurePosixPath
import subprocess
import struct
import sys
from zipfile import BadZipFile, ZipFile

from handheld_platform import active_sway_outputs
from handheld_input import capability_bits, is_gamepad
from installation import Library


ORIGINAL_FOLDER = "AM2ARM"

# SHA-256 of the Editions shortcuts previously supplied for these firmware menus.
_PORTS_MENU = {"a0a25a796b1019e0f0975aec2acffeba1c23910f79dde3f3bb712851827ea45e",
               "49d71f862243b626e008ee8c30684d984a81323e8bf5799c5a92f85cc9800f81"}
_APP_CONFIG = {"c2bfb17e72a5a02d1e0da02a2b92328a4a1b18fe156e0827d31beb4aa8fbd19a"}
_NEXTUI_MENU = {"76fc4509fb038783eedc686e05a7a160581f7a42ccf5109cc37030c9cc7bff62"}
_OLD_ENTRIES = {
    "ports/AM2ARM Editions.sh": {"": _PORTS_MENU},
    "roms/ports/AM2ARM Editions.sh": {"": _PORTS_MENU},
    "App/AM2ARM-Editions": {"config.json": _APP_CONFIG, "launch.sh": {
        "0635a63a63f08534cbf714f7182c504d0957f949a35406c36657a4a98ec1b6f0"}},
    "Apps/AM2ARM-Editions": {"config.json": _APP_CONFIG, "launch.sh": {
        "97c53f2f22c9dae5d587fcdc946c1fdfa87e6d067b49e907d21cb954fec1721c"}},
    "Tools/my355/AM2ARM Editions.pak": {"launch.sh": {
        "9b6db9fc7c1c91ef8f676d430514f9dfd25b4b3a60d459ed0c998e76ef129e20"}},
    "Tools/tg5040/AM2ARM Editions.pak": {"launch.sh": _NEXTUI_MENU},
    "Tools/tg5050/AM2ARM Editions.pak": {"launch.sh": _NEXTUI_MENU},
}


def retire_edition_entries(card):
    """Move unmodified obsolete menu entries into the player's data folder on upgrade."""
    card = card.resolve()
    for relative, expected in _OLD_ENTRIES.items():
        entry = card/relative
        backup = card/"AM2ARM-data/old-menu-entries"/relative
        try:
            if not entry.exists() or entry.resolve() != entry:
                continue
            if os.path.lexists(backup) or backup.resolve() != backup:
                continue
            if "" not in expected and {child.name for child in entry.iterdir()} != expected.keys():
                continue
            for name, digests in expected.items():
                file = entry/name
                if (file.is_symlink() or not file.is_file() or file.stat().st_size > 8192
                        or hashlib.sha256(file.read_bytes()).hexdigest() not in digests):
                    break
            else:
                backup.parent.mkdir(parents=True, exist_ok=True)
                entry.rename(backup)
        except (OSError, RuntimeError):
            # Read-only volumes and user-managed menu folders can still launch the game.
            continue


def find_original(app, card, ports):
    primary = card / ORIGINAL_FOLDER
    directories = [primary, card, app.parent, card / "am2arm-launcher", ports, app,
                   app / "patcher/input", card / "Downloads", card / "Download",
                   card / "AM2ARM/patcher/input", ports / "am2arm-launcher/AM2ARM/patcher/input"]
    if card.name.lower() == "roms" and card.parent != Path("/"):
        directories.extend([card.parent, card.parent / "Downloads"])
    found = None
    for folder in dict.fromkeys(directories):
        try:
            entries = list(folder.iterdir())
        except OSError:
            continue
        for path in entries:
            if path.suffix.lower() != ".zip" or not path.is_file():
                continue
            try:
                with ZipFile(path) as archive:
                    names = {name.lower() for name in archive.namelist()}
                if not any(PurePosixPath(name).name == "data.win"
                           and str(PurePosixPath(name).with_name("am2r.exe")) in names
                           for name in names):
                    continue
                candidate = path.resolve()
            except (OSError, BadZipFile):
                continue
            if found is not None and found != candidate:
                return None
            found = candidate
        if folder == primary and found is not None:
            return found
    return found


def board_model():
    try:
        stock_model = Path("/sys/class/anbernic_misc/model").read_bytes().strip().lower()
    except OSError:
        stock_model = b""
    if stock_model == b"rgds":
        return stock_model
    try:
        return Path("/proc/device-tree/model").read_bytes().rstrip(b"\0").lower()
    except OSError:
        return b""


def is_rg_ds(model):
    return any(name in model for name in (b"rg ds", b"rg-ds", b"rgds"))


def single_screen(backend):
    if backend == "direct":
        return True
    if os.environ.get("SWAYSOCK"):
        try:
            outputs = active_sway_outputs(os.environ)
            if outputs:
                return len(outputs) < 2
        except (OSError, ValueError, subprocess.SubprocessError):
            pass
    connected = 0
    for connector in Path("/sys/class/drm").glob("card*-*/status"):
        try:
            connected += connector.read_text().strip() == "connected"
        except OSError:
            continue
    if connected:
        return connected < 2
    return not is_rg_ds(board_model())


def remembered_edition(library):
    try:
        edition = library.choice.read_text().strip()
    except OSError:
        return None
    return edition if edition in ("standard", "dual") else None


def selected_game(library):
    edition = remembered_edition(library)
    return library.existing(edition) if edition else None


def dpad_up_held(input_class=Path("/sys/class/input"), devices=Path("/dev/input")):
    """Read the current D-pad state once, without grabbing the controller."""
    for entry in input_class.glob("event*"):
        try:
            caps = entry / "device/capabilities"
            keys = capability_bits((caps / "key").read_text())
            axes = capability_bits((caps / "abs").read_text())
            if not is_gamepad(keys, axes):
                continue
            with (devices / entry.name).open("rb", buffering=0) as pad:
                # Linux EVIOCGKEY with a 96-byte KEY_MAX bitmap and EVIOCGABS(ABS_HAT0Y).
                if 544 in keys or 103 in keys:
                    pressed = fcntl.ioctl(pad, 0x80604518, bytes(96))
                    if any(pressed[key // 8] & (1 << (key % 8)) for key in (544, 103) if key in keys):
                        return True
                if 17 in axes:
                    hat = fcntl.ioctl(pad, 0x80184551, bytes(24))
                    if struct.unpack_from("=i", hat)[0] < 0:
                        return True
        except (OSError, ValueError):
            continue
    return False


def resume_game(library, backend, held=dpad_up_held):
    edition = remembered_edition(library)
    if not edition or (edition == "dual" and backend == "direct") or held():
        return None
    return library.existing(edition)


if __name__ == "__main__":
    if sys.argv[1] == "screens":
        print(int(single_screen(sys.argv[2])))
    else:
        library = Library.from_environment()
        action = sys.argv[1]
        if action in ("resume", "setup"):
            if os.environ.get("AM2ARM_FRONTEND") == "ports" and os.environ.get("AM2ARM_DEVICE_PROFILE") in ("g350", "rg351p"):
                from ports_art import prepare_ports_art
                prepare_ports_art(library.ports, library.app)
            target = resume_game(library, os.environ["AM2ARM_DISPLAY_PATH"]) if action == "resume" else None
            if target:
                retire_edition_entries(library.card)
        else:
            target = selected_game(library)
        if target:
            print(target)
