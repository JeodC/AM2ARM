"""Model selection for the shared TrimUI launcher and installer."""
import os
from pathlib import Path
import re
import struct


from compat_display import AMBERELEC_PANELS, identify, read

DISPLAY_SIZES = {'brick': (1024, 768), 'smartpro': (1280, 720), 'smartpros': (1280, 720),
                 'flip': (640, 480), 'g350': (640, 480), 'rg351p': (480, 320)}


def display_size(device=None):
    device = device or os.environ.get('AM2ARM_TRIMUI_DEVICE')
    try:
        return DISPLAY_SIZES[device]
    except KeyError:
        raise RuntimeError('The display hardware has not been identified.') from None


def knulli_brick_board(model, release):
    return (model == 'sun50iw10'
            and bool({'OS_NAME=knulli', 'OS_NAME="knulli"'}.intersection(release.splitlines()))
            and read('/boot/boot/knulli.board') == 'trimui-brick')


def muos_brick_board(model, release):
    return (model == 'sun50iw10'
            and bool({'ID=muos', 'ID=buildroot', 'ID="muos"', 'ID="buildroot"'}.intersection(release.splitlines()))
            and read('/opt/muos/device/config/board/name') == 'tui-brick')


def darkos_g350(model, release):
    return (model == 'BatleXP G-G-G-G350!' and 'ID=debian' in release.splitlines()
            and read('/home/ark/.config/.DEVICE') == 'G350')


def firmware_audio_session(device):
    model, release = read('/proc/device-tree/model'), read('/etc/os-release')
    if device == 'g350' and darkos_g350(model, release):
        from darkos_audio import prepare_darkos_audio
        return prepare_darkos_audio
    if device == 'brick' and muos_brick_board(model, release):
        from muos_audio import prepare_muos_audio
        return prepare_muos_audio
    return None


def firmware_display_loader(device):
    if device in AMBERELEC_PANELS:
        return Path('/usr/lib/ld-linux-aarch64.so.1')
    if device == 'brick':
        model, release = read('/proc/device-tree/model'), read('/etc/os-release')
        if knulli_brick_board(model, release) or muos_brick_board(model, release):
            return Path('/lib/ld-linux-aarch64.so.1')
    return None


KNULLI_BRICK_FACE_KEYS = {"a": 305, "b": 304, "x": 307, "y": 308}
MUOS_CONTROLLER = '060000006d750000020000006f730000,muOS-Keys,'


def muos_mapping():
    for source in (os.environ.get('SDL_GAMECONTROLLERCONFIG', ''), read('/opt/muos/device/config/board/sdl_map')):
        for line in source.splitlines():
            if line.startswith(MUOS_CONTROLLER):
                return line
    return ''


def panel_mapping(device, darkos_database=Path('/opt/inttools/gamecontrollerdb.txt')):
    from nextui_controls import evdev_mapping
    if device == 'g350' and darkos_g350(read('/proc/device-tree/model'), read('/etc/os-release')):
        return evdev_mapping(device, database=darkos_database)
    return evdev_mapping(device)


def firmware_face_buttons(name, ids, keys, paths=None):
    from nextui_controls import firmware_face_buttons as original_faces
    if name == 'muOS-Keys' and muos_brick_board(read('/proc/device-tree/model'), read('/etc/os-release')):
        record = dict(field.split(':', 1) for field in muos_mapping().split(',') if ':' in field)
        order = sorted(keys)
        faces = {}
        for face in ('a', 'b', 'x', 'y'):
            button = re.fullmatch(r'b([0-9]{1,3})', record.get(face, ''))
            if not button or int(button[1]) >= len(order):
                break
            faces[face] = order[int(button[1])]
        if len(set(faces.values())) == 4:
            return faces
    if (name == "TRIMUI Brick Controller" and set(KNULLI_BRICK_FACE_KEYS.values()).issubset(keys)
            and knulli_brick_board(read("/proc/device-tree/model"), read("/etc/os-release"))):
        return KNULLI_BRICK_FACE_KEYS.copy()
    return original_faces(name, ids, keys, paths)


def brick_mappings(device="brick", input_root=Path("/sys/class/input")):
    from handheld_input import capability_bits
    from nextui_controls import brick_mappings as original_mappings, button_order

    model, release = read('/proc/device-tree/model'), read('/etc/os-release')
    if device == 'brick' and muos_brick_board(model, release):
        # The firmware includes four auxiliary keys before its game buttons.
        # GameMaker numbers gamepad keys first. Translate through actual evdev codes.
        mapping = muos_mapping()
        for entry in input_root.glob('event*'):
            pad = entry / 'device'
            try:
                if (pad/'name').read_text().strip() != 'muOS-Keys':
                    continue
                keys = capability_bits((pad/'capabilities/key').read_text())
                firmware, runner = sorted(keys), button_order(keys)
                def runner_button(match):
                    key = firmware[int(match[1])]
                    return ':b' + str(runner.index(key))
                return re.sub(r':b([0-9]{1,3})(?=,|$)', runner_button, mapping)
            except (OSError, IndexError, ValueError):
                continue
        return ''
    if device == "brick" and knulli_brick_board(model, release):
        for entry in input_root.glob("event*"):
            pad = entry / "device"
            try:
                name = (pad / "name").read_text().strip()
                if name != "TRIMUI Brick Controller":
                    continue
                keys = button_order(capability_bits((pad / "capabilities/key").read_text()))
                axes = capability_bits((pad / "capabilities/abs").read_text())
                ids = [int((pad / "id" / k).read_text(), 16) for k in ("bustype", "vendor", "product", "version")]
            except (OSError, ValueError):
                continue
            # KNULLI exports its triggers as keys. GameMaker numbers gamepad keys
            # before the multimedia keys; EmulationStation's SDL indices differ.
            buttons = {**KNULLI_BRICK_FACE_KEYS, "leftshoulder": 310,
                       "rightshoulder": 311, "lefttrigger": 312, "righttrigger": 313,
                       "back": 314, "start": 315, "guide": 316, "leftstick": 317, "rightstick": 318}
            if not {312, 313, 314, 315}.issubset(keys) or not {0, 1, 16, 17}.issubset(axes):
                continue
            row = [struct.pack("<IIII", *ids).hex(), name]
            row.extend(f"{label}:b{keys.index(code)}" for label, code in buttons.items() if code in keys)
            return ",".join(row) + ",leftx:a0,lefty:a1,dpup:h0.1,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,platform:Linux,"
    return original_mappings(device)


def current_device():
    frontend = os.environ.get('PLATFORM', '')
    model, cpu = read('/proc/device-tree/model'), read('/proc/cpuinfo')
    menu = os.environ.get('AM2ARM_FRONTEND')
    if frontend == 'tg5040':
        frontend = os.environ.get('DEVICE', '')
    release = read('/etc/os-release')
    if knulli_brick_board(model, release) or muos_brick_board(model, release):
        frontend = 'brick'
    try:
        return identify(model, cpu, frontend, release)
    except RuntimeError as error:
        # Only older firmware with no board identifier needs these fallbacks.
        if not str(error).startswith('Unrecognized'):
            raise
        if darkos_g350(model, release):
            return 'g350'
        if menu == 'nextui' and os.environ.get('PLATFORM') == 'tg5040' and frontend in ('brick','smartpro'):
            return frontend
        if menu != 'stock':
            raise
        mainui = Path('/usr/trimui/bin/MainUI')
        if not mainui.is_file():
            raise
        content = mainui.read_bytes()
        if b'Trimui Brick Pro\0' in content:
            raise RuntimeError('This board requires another hardware profile.') from error
        models = [('smartpros', b'Trimui Smart Pro S\0'), ('smartpro', b'Trimui Smart Pro\0'), ('brick', b'Trimui Brick\0')]
        found = [device for device, label in models if label in content]
        if len(found) == 1:
            return found[0]
        if not found and 'lcd=jd9168' in read('/proc/cmdline').split():
            return 'brick'
        raise
