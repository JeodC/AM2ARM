"""Select one firmware display environment for installation and gameplay."""
import json
import os
from pathlib import Path
import sys
from compat_display import display_inventory, library_dirs
from handheld_platform import AmbiguousWaylandSession, wayland_environment
from trimui_device import current_device


def resolve_display(frontend, env, session=wayland_environment, device=current_device):
    if frontend == 'ports':
        try:
            selected = session(env)
            return 'ports', selected
        except AmbiguousWaylandSession:
            raise
        except (RuntimeError, OSError):
            pass
    try:
        profile = device()
    except (OSError, RuntimeError) as error:
        raise RuntimeError('No supported display was found. Send am2arm-launcher/AM2ARM/logs/compatibility.txt with your model and firmware.') from error
    return 'direct', dict(env, AM2ARM_DEVICE_PROFILE=profile)


def choose_backend(frontend, env, session=wayland_environment, device=current_device):
    return resolve_display(frontend, env, session, device)[0]


if __name__ == '__main__':
    try:
        backend, env = resolve_display(os.environ['AM2ARM_FRONTEND'], os.environ)
        if len(sys.argv) == 1:
            print(backend)
        elif sys.argv[1:2] == ['--exec'] and len(sys.argv) >= 3:
            os.execvpe(sys.argv[2], sys.argv[2:], dict(env, AM2ARM_DISPLAY_PATH=backend))
        else:
            raise SystemExit('Expected --exec followed by a session command.')
    except RuntimeError as error:
        if error.__cause__:
            print(error.__cause__, file=sys.stderr)
            card = Path(os.environ.get('AM2ARM_GAME_CARD') or '/')
            inventory = display_inventory(Path('/sys/class/drm'), library_dirs(card, 'generic'))
            print('Display inventory:', json.dumps(inventory, sort_keys=True), file=sys.stderr)
        print(error, file=sys.stderr)
        raise SystemExit(1)
