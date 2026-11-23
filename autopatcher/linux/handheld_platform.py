"""Detect the existing display session without changing the firmware."""
import os
import json
from pathlib import Path
import socket
import stat
import struct
import subprocess
import time


def active_sway_outputs(environment):
    result = subprocess.run(['swaymsg', '-r', '-t', 'get_outputs'], env=environment,
                            capture_output=True, text=True, check=True, timeout=3)
    outputs = json.loads(result.stdout)
    if not isinstance(outputs, list):
        raise ValueError('Sway returned an invalid output list.')
    return [output for output in outputs if isinstance(output, dict) and output.get('name')
            and output.get('active', output.get('current_mode', True))
            and output.get('connected', True) and output.get('enabled', True)
            and output.get('power', output.get('dpms', True))]


def sway_output(environment):
    if not environment.get('SWAYSOCK'):
        return None
    outputs = active_sway_outputs(environment)
    if not outputs:
        raise RuntimeError('No powered screen is available for the installer.')
    return next((output['name'] for output in outputs if output.get('focused')),
                outputs[0]['name'])


def place_sway_window(pid, output, environment):
    command = f'[pid={int(pid)}] move container to output {json.dumps(output)}, focus'
    deadline = time.monotonic() + 5
    while time.monotonic() < deadline:
        result = subprocess.run(['swaymsg', '-r', '-t', 'command', command], env=environment,
                                capture_output=True, text=True, timeout=1)
        if result.returncode == 0:
            replies = json.loads(result.stdout)
            if replies and all(reply.get('success') for reply in replies):
                return
        time.sleep(.05)
    raise RuntimeError('The installer window could not be placed on the active screen.')


def responds_to_wayland(endpoint):
    # wl_display.sync creates callback 2. With no registry bound its done event
    # is the first reply. Checking it excludes stale and non-Wayland sockets.
    packet = struct.Struct('=III')
    try:
        if not stat.S_ISSOCK(endpoint.stat().st_mode):
            return False
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
            client.settimeout(0.5)
            client.connect(str(endpoint))
            client.sendall(packet.pack(1, 12 << 16, 2))
            with client.makefile('rb') as stream:
                reply = stream.read(packet.size)
        return len(reply) == packet.size and packet.unpack(reply)[:2] == (2, 12 << 16)
    except OSError:
        return False


class AmbiguousWaylandSession(RuntimeError):
    pass


def wayland_environment(environment):
    display = Path(environment.get('WAYLAND_DISPLAY') or 'wayland-0')
    explicit = environment.get('XDG_RUNTIME_DIR')
    if explicit:
        folders = [Path(explicit)]
    else:
        uid = os.getuid()
        folders = [Path('/run/user') / str(uid), Path('/run') / f'{uid}-runtime-dir',
                   Path('/var/run'), Path('/run')]
    if display.is_absolute():
        folders = list(dict.fromkeys([display.parent, *folders]))

    for folder in folders:
        preferred = folder / (display.name if display.is_absolute() else display)
        if responds_to_wayland(preferred):
            # An absolute display outside XDG_RUNTIME_DIR must not change where
            # the client looks for other services such as its audio socket.
            if explicit and Path(explicit) != preferred.parent:
                return dict(environment, WAYLAND_DISPLAY=str(preferred))
            return dict(environment, XDG_RUNTIME_DIR=str(preferred.parent), WAYLAND_DISPLAY=preferred.name)
        try:
            others = [p for p in folder.glob('wayland-*') if p != preferred
                      and p.name[8:].isdecimal() and p.lstat().st_uid == os.getuid()
                      and responds_to_wayland(p)]
        except OSError:
            continue
        if len(others) == 1:
            if explicit and Path(explicit) != folder:
                return dict(environment, WAYLAND_DISPLAY=str(others[0]))
            return dict(environment, XDG_RUNTIME_DIR=str(folder), WAYLAND_DISPLAY=others[0].name)
        if others:
            raise AmbiguousWaylandSession('Multiple Wayland displays are active. Open AM2ARM from the handheld menu.')
    raise RuntimeError('No responding Wayland display was found.')
