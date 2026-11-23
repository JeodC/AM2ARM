"""Honor the spruceOS Exit game binding while an AM2ARM game owns its private display."""
import json
import os
from pathlib import Path
import re
import time

from handheld_input import EVENT


class SpruceMenuExit:
    def __init__(self, inputs, key, tap, hold, seconds):
        self.inputs, self.key = inputs, key
        self.tap, self.hold, self.seconds = tap, hold, seconds
        self.pressed = None
        self.hold_deadline = 0
        self.others = set()

    @classmethod
    def open(cls, card, device=None, key=None, volume=None):
        try:
            settings = json.loads((card/'Saves/spruce/spruce-config.json').read_text())
            buttons = settings['menuOptions']['Button Settings']
            tap = buttons.get('tapMenuAction', {}).get('selected') == 'Exit game'
            hold = buttons.get('holdMenuAction', {}).get('selected') == 'Exit game'
            if not (tap or hold):
                return None
            seconds = float(buttons.get('menuHoldTime', {}).get('selected', 1))
            if not 0 < seconds < 60:
                return None
            if device is None:
                value = os.environ.get('EVENT_PATH_READ_INPUTS_SPRUCE', '')
                if re.fullmatch(r'/dev/input/event[0-9]+', value):
                    device = Path(value)
                else:
                    pads = [p for p in Path('/sys/class/input').glob('event*')
                            if (p/'device/name').read_text().strip().casefold() == 'trimui player1']
                    if len(pads) != 1:
                        return None
                    device = Path('/dev/input')/pads[0].name
            if key is None:
                fields = (os.environ.get('B_MENU') or '1 316').split()
                if len(fields) != 2 or fields[0] != '1':
                    return None
                key = int(fields[1])
            inputs = [os.open(device, os.O_RDONLY | os.O_NONBLOCK)]
            if volume is None:
                value = os.environ.get('EVENT_PATH_VOLUME', '')
                if re.fullmatch(r'/dev/input/event[0-9]+', value):
                    volume = Path(value)
            if volume and volume != device:
                try:
                    inputs.append(os.open(volume, os.O_RDONLY | os.O_NONBLOCK))
                except OSError:
                    pass
            return cls(inputs, key, tap, hold, seconds)
        except (OSError, KeyError, ValueError, AttributeError, TypeError):
            return None

    def requested(self):
        events = []
        for fd in self.inputs:
            try:
                data = os.read(fd, EVENT.size * 128)
            except BlockingIOError:
                continue
            except OSError:
                self.pressed = None
                continue
            events.extend((*event, fd) for event in EVENT.iter_unpack(data))
        for sec, usec, kind, code, value, fd in sorted(events, key=lambda event: event[:2]):
            if kind == 0 and code == 3:  # SYN_DROPPED
                self.pressed = None
                self.others.clear()
            # The Smart Pro S reports its D-pad and both triggers as axes.
            if kind == 3 and code in (2, 5, 16, 17):
                active = value != 0 if code in (16, 17) else value == 255
                if active:
                    self.others.add((fd, code))
                    self.pressed = None
                else:
                    self.others.discard((fd, code))
                continue
            if kind != 1:
                continue
            if fd != self.inputs[0] or code != self.key:
                if value == 1:
                    self.others.add((fd, code))
                    self.pressed = None
                elif value == 0:
                    self.others.discard((fd, code))
                continue
            now = sec + usec / 1000000
            if value == 1 and not self.others:
                self.pressed = now
                self.hold_deadline = time.monotonic() + self.seconds
            elif value == 0 and self.pressed is not None:
                duration = now - self.pressed
                self.pressed = None
                if duration >= 0 and (self.hold if duration >= self.seconds else self.tap):
                    return True
        if self.hold and self.pressed is not None and time.monotonic() >= self.hold_deadline:
            self.pressed = None
            return True
        return False

    def __enter__(self):
        return self

    def __exit__(self, *_):
        for fd in self.inputs:
            os.close(fd)
