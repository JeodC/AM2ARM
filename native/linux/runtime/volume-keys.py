"""RG DS volume keys for the native launcher; no input grab or remapping."""
from pathlib import Path
import argparse
import os
import select
import signal
import struct
import subprocess
import sys
import time

EVENT = struct.Struct('llHHi')
VOLUME_DOWN, VOLUME_UP = 114, 115


def volume_device():
    for entry in sorted(Path('/sys/class/input').glob('event*')):
        if (entry / 'device/name').read_text().strip() != 'ANBERNIC-rk3568-keys':
            continue
        words = (entry / 'device/capabilities/key').read_text().split()
        bits = int(''.join(word.zfill(16) for word in words), 16)
        if all(bits & (1 << key) for key in (VOLUME_DOWN, VOLUME_UP)):
            return Path('/dev/input') / entry.name
    raise RuntimeError('RG DS volume input is unavailable')


def adjust(key):
    change = '5%-' if key == VOLUME_DOWN else '5%+'
    subprocess.run(['amixer', '-q', '-c', '0', '-M', 'sset', 'DAC', change],
                   check=True, timeout=2)


def listen(parent):
    device = volume_device()
    fd = os.open(device, os.O_RDONLY | os.O_NONBLOCK)
    held = None
    repeat_at = 0.0
    dropped = False
    print('Volume keys ready: ' + str(device), flush=True)
    try:
        while True:
            try:
                os.kill(parent, 0)
            except ProcessLookupError:
                return
            now = time.monotonic()
            timeout = min(1.0, max(0.0, repeat_at - now)) if held else 1.0
            readable, _, _ = select.select([fd], [], [], timeout)
            if readable:
                data = os.read(fd, EVENT.size * 64)
                if not data:
                    return
                for at in range(0, len(data), EVENT.size):
                    _, _, kind, code, value = EVENT.unpack_from(data, at)
                    if kind == 0 and code == 3:
                        dropped = True
                        held = None
                    elif dropped:
                        if kind == 0 and code == 0:
                            dropped = False
                    elif kind == 1 and code in (VOLUME_DOWN, VOLUME_UP):
                        if value == 1:
                            adjust(code)
                            held = code
                            repeat_at = time.monotonic() + 0.4
                        elif value == 0 and held == code:
                            held = None
            if held and time.monotonic() >= repeat_at:
                adjust(held)
                repeat_at = time.monotonic() + 0.15
    finally:
        os.close(fd)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--parent', required=True, type=int)
    options = parser.parse_args()
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
    signal.signal(signal.SIGINT, lambda *_: sys.exit(0))
    listen(options.parent)
