"""Use the built-in TrimUI controller's printed buttons and analog axes."""
from pathlib import Path
import os
import struct


def button_order(keys):
    return sorted(k for k in keys if 288 <= k < 767) + sorted(k for k in keys if 0 <= k < 288)


def firmware_face_buttons(name, device_ids, keys, paths=None):
    if name.casefold() == 'miyoo player1' and {304, 305, 307, 308} <= set(keys):
        return dict(a=305, b=304, x=307, y=308)
    if name.casefold() == 'trimui player1' and os.environ.get('AM2ARM_TRIMUI_DEVICE') == 'smartpros':
        return dict(a=305, b=304, x=308, y=307) if {304, 305, 307, 308} <= set(keys) else None
    if 'trimui' not in name.lower():
        return None
    order = button_order(keys)
    if len(order) < 4:
        return None
    return dict(a=order[1], b=order[0], x=order[3], y=order[2])


def brick_mappings(device='brick'):
    rows = []
    label = {'brick': 'TrimUI Brick', 'smartpro': 'TrimUI Smart Pro'}[device]
    stick_buttons = 'leftstick:b9,rightstick:b10,' if device == 'brick' else ''
    for entry in Path('/sys/class/input').glob('event*'):
        device_path = entry/'device'
        try:
            name = (device_path/'name').read_text().strip()
            if 'trimui' not in name.lower():
                continue
            ids = [int((device_path/'id'/part).read_text(), 16)
                   for part in ('bustype', 'vendor', 'product', 'version')]
            guid = struct.pack('<IIII', *ids).hex()
            # Match the printed letters to the game's named buttons,
            # just as the installer does, without changing saved bindings.
            rows.append(guid+','+label+','+
                'a:b1,b:b0,x:b3,y:b2,back:b6,start:b7,guide:b8,'
                'leftshoulder:b4,rightshoulder:b5,'+stick_buttons+
                'leftx:a0,lefty:a1,rightx:a3,righty:a4,lefttrigger:a2,righttrigger:a5,'
                'dpup:h0.1,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,platform:Linux,')
        except (OSError, ValueError):
            continue
    return '\n'.join(dict.fromkeys(rows))


def evdev_mapping(device, input_root=Path('/sys/class/input')):
    from handheld_input import capability_bits
    pad_name, x, y = {'flip': ('MIYOO Player1', 307, 308),
                      'smartpros': ('TRIMUI Player1', 308, 307)}[device]
    for entry in input_root.glob('event*'):
        pad = entry/'device'
        try:
            if (pad/'name').read_text().strip().casefold() != pad_name.casefold():
                continue
            ids = [int((pad/'id'/key).read_text(), 16) for key in ('bustype', 'vendor', 'product', 'version')]
            keys = button_order(capability_bits((pad/'capabilities/key').read_text()))
            axes = sorted(k for k in capability_bits((pad/'capabilities/abs').read_text()) if k < 16)
            fields = [struct.pack('<IIII', *ids).hex(), pad_name]
            for key, code in [('a', 305), ('b', 304), ('x', x), ('y', y),
                              ('leftshoulder', 310), ('rightshoulder', 311), ('back', 314),
                              ('start', 315), ('guide', 316), ('leftstick', 317), ('rightstick', 318)]:
                if code in keys:
                    fields.append(f'{key}:b{keys.index(code)}')
            for key, code in [('leftx', 0), ('lefty', 1), ('lefttrigger', 2),
                              ('rightx', 3), ('righty', 4), ('righttrigger', 5)]:
                if code in axes:
                    fields.append(f'{key}:a{axes.index(code)}')
            return ','.join(fields)+',dpup:h0.1,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,platform:Linux,'
        except (OSError, ValueError):
            continue
    return ''
