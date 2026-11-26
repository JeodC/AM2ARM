"""Resolve the display passed to the game and its installer."""
import json
import os
from pathlib import Path
import shutil
import sys

from compat_display import display_inventory, library_dirs
from handheld_platform import AmbiguousWaylandSession, wayland_environment
from trimui_device import current_device


def same_socket(requested, selected):
    wanted = Path(requested["WAYLAND_DISPLAY"])
    actual = Path(selected["WAYLAND_DISPLAY"])
    if not wanted.is_absolute():
        if not requested.get("XDG_RUNTIME_DIR"):
            return False
        wanted = Path(requested["XDG_RUNTIME_DIR"]) / wanted
    if not actual.is_absolute():
        if not selected.get("XDG_RUNTIME_DIR"):
            return False
        actual = Path(selected["XDG_RUNTIME_DIR"]) / actual
    return wanted == actual


def ports_prerequisites(env):
    return (os.access("/lib/ld-linux-aarch64.so.1", os.X_OK)
            and shutil.which("python3", path=env.get("PATH", os.defpath)) is not None)


def resolve_display(frontend, env, session=wayland_environment, device=current_device,
                    ports_ready=ports_prerequisites):
    if frontend == "ports" or env.get("WAYLAND_DISPLAY"):
        try:
            selected = session(env)
            if ports_ready(selected) and (frontend == "ports" or same_socket(env, selected)):
                return "ports", selected
        except AmbiguousWaylandSession:
            if frontend == "ports":
                raise
        except (RuntimeError, OSError):
            pass
    try:
        profile = device()
    except (OSError, RuntimeError) as error:
        raise RuntimeError("No supported display was found. Send am2arm-launcher/AM2ARM/logs/compatibility.txt with your model and firmware.") from error
    return "direct", dict(env, AM2ARM_DEVICE_PROFILE=profile)


if __name__ == "__main__":
    try:
        backend, env = resolve_display(os.environ["AM2ARM_FRONTEND"], os.environ)
        if len(sys.argv) == 1:
            print(backend)
        elif sys.argv[1:2] == ["--exec"] and len(sys.argv) >= 3:
            os.execvpe(sys.argv[2], sys.argv[2:], dict(env, AM2ARM_DISPLAY_PATH=backend))
        else:
            raise SystemExit("Expected --exec followed by a session command.")
    except RuntimeError as error:
        if error.__cause__:
            print(error.__cause__, file=sys.stderr)
            card = Path(os.environ.get("AM2ARM_GAME_CARD") or "/")
            inventory = display_inventory(Path("/sys/class/drm"), library_dirs(card, "generic"))
            print("Display inventory:", json.dumps(inventory, sort_keys=True), file=sys.stderr)
        print(error, file=sys.stderr)
        raise SystemExit(1)
