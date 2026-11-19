"""Choose the firmware display path before starting the installer."""
import os
import sys
from handheld_platform import wayland_environment
from trimui_device import current_device


def choose_backend(frontend, env, session=wayland_environment, device=current_device):
    if frontend == 'ports':
        try:
            session(env)
            return 'ports'
        except (RuntimeError, OSError):
            pass
    try:
        device()
    except (OSError, RuntimeError) as error:
        raise RuntimeError('No supported display was found. Send AM2ARM/logs/compatibility.txt with your model and firmware.') from error
    return 'direct'


if __name__ == '__main__':
    try:
        print(choose_backend(os.environ['AM2ARM_FRONTEND'], os.environ))
    except RuntimeError as error:
        if error.__cause__:
            print(error.__cause__, file=sys.stderr)
        print(error, file=sys.stderr)
        raise SystemExit(1)
