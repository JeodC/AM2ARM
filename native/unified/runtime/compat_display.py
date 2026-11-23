"""Identify the handheld and locate its native ARM64 graphics libraries."""
from pathlib import Path
import os
import re

SDL_NAMES = ('libSDL2-2.0.so.0', 'libSDL2.so', 'libSDL2-2.0.so')
MALI_NAMES = ('libmali.so.1', 'libmali.so.0', 'libmali.so', 'libMali.so')
EGL_NAMES = ('libEGL.so.1', 'libEGL.so') + MALI_NAMES
GLES_NAMES = ('libGLESv2.so.2', 'libGLESv2.so') + MALI_NAMES


def read(path):
    try:
        return Path(path).read_text(errors='replace').strip('\0\r\n ')
    except OSError:
        return ''


def identify(model, cpu, frontend_model, release):
    hardware = (model + '\n' + cpu).lower()
    if any(s in hardware for s in ('mini flip', 'sstar', 'tg4040')):
        raise RuntimeError('This board requires another hardware profile.')
    if 'tg5050' in hardware or 'trimui smart pro s' in model.lower():
        if any(s in hardware for s in ('sun50iw10', 'tg5040', 'tg3040')):
            raise RuntimeError('Conflicting TrimUI board identifiers.')
        return 'smartpros'
    if 'miyoo' in model.lower() and 'rk3566' in model.lower() and '355' in model:
        return 'flip'
    if 'tg5040' in hardware:
        return 'smartpro'
    if 'tg3040' in hardware:
        return 'brick'
    if re.search(r'\bmy355\b', release, re.I) and 'miyoo' in model.lower():
        return 'flip'
    if 'sun50iw10' in hardware and frontend_model.lower() in ('smartpro', 'brick'):
        return frontend_model.lower()
    if ('sun55iw3' in hardware or 'a523' in hardware) and frontend_model.lower() in (
            'smartpros', 'tg5050', 'trimui_smart_pro_s', 'spruce_trimui_smart_pro_s'):
        return 'smartpros'
    raise RuntimeError('Unrecognized display hardware. Please send compatibility.txt.')


def video_drivers(device, names):
    if device == 'smartpros':
        return [name for name in names if name and name.lower() == 'kmsdrm']
    drivers = list(dict.fromkeys(n for n in names if n and n.lower() not in
                                 ('wayland', 'x11', 'dummy', 'offscreen')))
    if device == 'flip':
        drivers.sort(key=lambda n: n.lower() != 'kmsdrm')
    return drivers


def library_dirs(card, device):
    if device == 'smartpros':
        vendor = [Path('/usr/lib'), card/'Persistent/portmaster/lib', card/'spruce/flip/lib',
                  card/'spruce/brick/sdl2', Path('/usr/trimui/lib')]
    elif device == 'flip':
        vendor = [card/'spruce/flip/lib', card/'.system/my355/lib', Path('/usr/miyoo/lib')]
    elif device in ('brick', 'smartpro'):
        vendor = [Path('/usr/trimui/lib'), card/'.system/tg5040/lib']
    else:
        vendor = []
    system = [Path(p) for p in ('/usr/lib/aarch64-linux-gnu', '/lib/aarch64-linux-gnu',
              '/usr/lib64', '/lib64', '/usr/lib', '/lib', '/usr/lib/egl', '/usr/lib/mali')]
    provided = [Path(p) for p in os.environ.get('LD_LIBRARY_PATH', '').split(':')
                if p.startswith('/') and 'lib32' not in p]
    return list(dict.fromkeys(vendor + system + provided))


def library_candidates(folders, names):
    found = []
    for folder in folders:
        for name in names:
            try:
                path = (folder/name).resolve(strict=True)
                if path in found or not path.is_file():
                    continue
                with path.open('rb') as src:
                    h = src.read(20)
                if h[:6] == b'\x7fELF\x02\x01' and h[16:20] == b'\x03\x00\xb7\x00':
                    found.append(path)
            except (OSError, RuntimeError):
                continue
    return found


def display_inventory(drm, folders):
    """Report hints for an unknown firmware without taking over its screen."""
    connected = {}
    for status in sorted(drm.glob('card*-*/status')):
        if read(status) == 'connected':
            modes = read(status.with_name('modes')).splitlines()
            connected[status.parent.name] = modes[0] if modes else None
    libraries = {}
    for label, names in [('SDL2', SDL_NAMES), ('EGL', EGL_NAMES), ('GLES2', GLES_NAMES)]:
        libraries[label] = list(dict.fromkeys(p.name for p in library_candidates(folders, names)))
    return {'connected_drm': connected, 'arm64_libraries': libraries}
