"""Run AM2ARM with app-local display, audio and persistent save support."""
from pathlib import Path
import fcntl
import filecmp
import json
import os
import signal
import shutil
import struct
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
RUNTIME = ROOT / 'runtime'
STATE = ROOT / 'state'
CHILDREN = []

def display_session(environment):
    env = dict(environment)
    env['XDG_RUNTIME_DIR'] = env.get('XDG_RUNTIME_DIR') or '/var/run'
    env['WAYLAND_DISPLAY'] = env.get('WAYLAND_DISPLAY') or 'wayland-0'
    return env

def prepare_display_config(config, edition, single_panel):
    if config.exists():
        return
    if edition == 'standard' and single_panel:
        # The game selects the aspect and scale once its real drawable exists.
        config.write_text('[Screen]\nNano=0\n')
    else:
        config.write_text('[Screen]\nFullscreen=0\nScale=2\nWidescreen=0\nAspectRatio=0\nNano=0\n'
                          '[DualScreen]\nDeviceProfile=1\nSwapScreens=0\n')


def firmware_audio(environment):
    server = environment.get('PULSE_SERVER')
    if not server:
        endpoint = Path(environment['XDG_RUNTIME_DIR']) / 'pulse/native'
        if not endpoint.is_socket():
            return None
        server = 'unix:' + str(endpoint)
    env = dict(environment, PULSE_SERVER=server)
    try:
        result = subprocess.run(['pactl', 'info'], env=env, stdout=subprocess.DEVNULL,
                                stderr=subprocess.DEVNULL, timeout=2)
        return env if result.returncode == 0 else None
    except (OSError, subprocess.TimeoutExpired):
        return None

def rgds_virtual_mapping(model, name, device_path, guid):
    if (model not in ('Anbernic RG DS', 'Anbernic RG DS Plus')
            or name != 'Sony Interactive Entertainment DualSense Wireless Controller'
            or '/devices/virtual/misc/uhid/' not in device_path):
        return None
    return (guid + ',Anbernic RG DS virtual controller,'
            'a:b1,b:b0,x:b2,y:b3,back:b8,guide:b10,start:b9,'
            'leftshoulder:b4,rightshoulder:b5,leftstick:b11,rightstick:b12,'
            'leftx:a0,lefty:a1,rightx:a3,righty:a4,lefttrigger:a2,righttrigger:a5,'
            'dpup:h0.1,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,platform:Linux,')

def controller_mappings():
    original = (ROOT / 'data/gamecontrollerdb.txt').read_text()
    try:
        model = Path('/proc/device-tree/model').read_text().rstrip('\0\n')
    except OSError:
        return original
    for entry in Path('/sys/class/input').glob('event*'):
        device = entry / 'device'
        try:
            name = (device / 'name').read_text().strip()
            ids = [int((device / 'id' / field).read_text(), 16)
                   for field in ('bustype', 'vendor', 'product', 'version')]
            guid = struct.pack('<IIII', *ids).hex()
            mapping = rgds_virtual_mapping(model, name, str(device.resolve()), guid)
        except (OSError, ValueError):
            continue
        if mapping is not None:
            return original.rstrip() + '\n' + mapping + '\n'
    return original

def prepare_controller_database(directory, mappings):
    # This runner loads the saved database before enumerating controllers.
    # Its environment override does not register entries in that database.
    path = directory / 'gamecontrollerdb.txt'
    begin = '# BEGIN AM2ARM DEVICE MAPPINGS\n'
    end = '# END AM2ARM DEVICE MAPPINGS\n'
    previous = path.read_text() if path.exists() else ''
    custom = previous
    if begin in previous:
        prefix, _, rest = previous.partition(begin)
        managed, separator, suffix = rest.partition(end)
        if not separator:
            raise RuntimeError('Incomplete generated controller database; original file preserved.')
        custom = prefix + suffix
    elif previous:
        backup = directory / ('gamecontrollerdb.before-am2arm-' + str(time.time_ns()) + '.txt')
        shutil.copy2(path, backup)
    # User mappings follow the defaults because the runner gives the last
    # matching database entry priority. Never rewrite config.ini bindings.
    content = begin + mappings.rstrip() + '\n' + end + custom
    if content != previous:
        temporary = None
        try:
            with tempfile.NamedTemporaryFile(mode='w', encoding='utf-8', dir=directory,
                                             prefix='.gamecontrollerdb-', delete=False) as stream:
                temporary = Path(stream.name)
                stream.write(content)
            temporary.replace(path)
        finally:
            if temporary is not None and temporary.exists():
                temporary.unlink()

def same_save_tree(left, right):
    """Compare saved data before switching an existing install to its copy."""
    left_entries = {entry.name: entry for entry in left.iterdir()}
    right_entries = {entry.name: entry for entry in right.iterdir()}
    if left_entries.keys() != right_entries.keys():
        return False
    for name, source in left_entries.items():
        target = right_entries[name]
        if source.is_symlink() or target.is_symlink():
            if not (source.is_symlink() and target.is_symlink()
                    and os.readlink(source) == os.readlink(target)):
                return False
        elif source.is_dir() and target.is_dir():
            if not same_save_tree(source, target):
                return False
        elif not (source.is_file() and target.is_file()
                  and filecmp.cmp(source, target, shallow=False)):
            return False
    return True

def bind_save_directory(native, portable):
    """Keep the engine's native save path on the card, preserving older data."""
    native, portable = Path(native), Path(portable)
    native.parent.mkdir(parents=True, exist_ok=True)
    portable.parent.mkdir(parents=True, exist_ok=True)
    if native.is_symlink() and native.resolve() == portable.resolve():
        portable.mkdir(exist_ok=True)
        return None
    backup = None
    if native.exists():
        if not native.is_dir():
            raise RuntimeError('The native save location is not a directory.')
        if portable.exists() and any(portable.iterdir()):
            if not same_save_tree(native, portable):
                raise RuntimeError('Two different save folders were found. Keep the desired state folder before launching.')
        else:
            shutil.copytree(native, portable, dirs_exist_ok=True, symlinks=True)
    else:
        portable.mkdir(exist_ok=True)
    if os.path.lexists(native):
        backup = native.with_name(native.name + '.before-portable-' + str(time.time_ns()))
        native.rename(backup)
    try:
        native.symlink_to(portable.resolve(), target_is_directory=True)
    except OSError:
        if backup is not None:
            backup.rename(native)
        raise
    return backup

def start(command, env, log, cwd=None):
    stream = (STATE / log).open('w')
    try:
        process = subprocess.Popen(command, cwd=cwd, env=env, stdout=stream,
                                   stderr=subprocess.STDOUT, start_new_session=True)
    finally:
        stream.close()
    CHILDREN.append(process)
    return process

def finish():
    for process in reversed(CHILDREN):
        if process.poll() is None:
            try:
                os.killpg(process.pid, signal.SIGTERM)
                process.wait(timeout=3)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
            except ProcessLookupError:
                pass

def wait_for(process, check, label):
    for _ in range(100):
        if process.poll() is not None:
            raise RuntimeError(label + ' closed during startup. See state logs.')
        if check():
            return
        time.sleep(.1)
    raise RuntimeError(label + ' did not become ready. See state logs.')

def main():
    STATE.mkdir(exist_ok=True)
    settings = json.loads((ROOT / 'edition.json').read_text())
    # Both editions share the device displays and PCM output; allow only one.
    with open('/tmp/am2r-linux.lock', 'a') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise RuntimeError('AM2ARM or the previous AM2R build is already running.')
        return run(settings)

def run(settings):
    env = display_session(os.environ)
    env.update(EGL_PLATFORM='wayland', SDL_VIDEODRIVER='x11',
               XDG_CONFIG_HOME=str(STATE / 'config'), XDG_DATA_HOME=str(STATE / 'data'))
    for key in ('XDG_CONFIG_HOME', 'XDG_DATA_HOME'):
        Path(env[key]).mkdir(exist_ok=True)
    options = Path(env['XDG_CONFIG_HOME']) / settings['game_name']
    # This pinned Linux runner uses ~/.config directly, ignoring XDG_CONFIG_HOME.
    # Point only this game's directory at the card; never change HOME or global config.
    bind_save_directory(Path.home() / '.config' / settings['game_name'], options)
    env['AM2ARM_SAVE_DIR'] = str(options.resolve())
    env['AM2ARM_BROWSE_DIR'] = str(next((p for p in (Path('/storage/roms'), Path('/roms'), Path('/mnt/mmc')) if p.is_dir()), ROOT.parent))
    prepare_display_config(options/'config.ini', settings['edition'], env.get('AM2ARM_SINGLE_SCREEN') == '1')
    prepare_controller_database(options, controller_mappings())
    env['LD_LIBRARY_PATH'] = str(RUNTIME / 'lib')
    touch = Path('/sys/class/anbernic_misc/tpctrl')
    previous_touch = None
    with tempfile.TemporaryDirectory(prefix='am2r-linux-') as temporary:
        work = Path(temporary)
        try:
            number = next(n for n in range(42, 100) if not Path(f'/tmp/.X11-unix/X{n}').exists()
                          and not Path(f'/tmp/.X{n}-lock').exists())
            authority = work / 'authority'
            fields = [b'', str(number).encode(), b'MIT-MAGIC-COOKIE-1', os.urandom(16)]
            authority.write_bytes(struct.pack('>H', 65535) + b''.join(struct.pack('>H', len(f)) + f for f in fields))
            authority.chmod(0o600)
            env.update(XAUTHORITY=str(authority), DISPLAY=f':{number}')
            xserver = start([str(RUNTIME / 'bin/Xwayland'), env['DISPLAY'], '-rootless', '-shm',
                             '-nolisten', 'tcp', '-auth', str(authority),
                             '-xkbdir', '/usr/share/X11/xkb', '-noreset'],
                            env, 'display.log', RUNTIME / 'bin')
            wait_for(xserver, lambda: Path(f'/tmp/.X11-unix/X{number}').exists(), 'Input display')
            existing_audio = firmware_audio(env)
            if existing_audio is not None:
                env = existing_audio
                print('Using firmware audio server.', flush=True)
            else:
                for folder in ('pulse-run', 'pulse-state'):
                    (work / folder).mkdir(mode=0o700)
                cookie = work / 'pulse-cookie'
                cookie.write_bytes(os.urandom(256))
                cookie.chmod(0o600)
                env.update(PULSE_RUNTIME_PATH=str(work / 'pulse-run'),
                           PULSE_STATE_PATH=str(work / 'pulse-state'),
                           PULSE_COOKIE=str(cookie), PULSE_SERVER='unix:' + str(work / 'audio'))
                audio = start(['pulseaudio', '-n', '--daemonize=no', '--exit-idle-time=-1',
                               '--high-priority=no', '--realtime=no', '--log-target=stderr',
                               '-L', f'module-native-protocol-unix socket={work}/audio auth-cookie={cookie}',
                               '-L', 'module-alsa-sink sink_name=am2r device=hw:0,0 rate=48000 channels=2 tsched=0'],
                              env, 'audio.log')
                def audio_ready():
                    return subprocess.run(['pactl', 'info'], env=env, stdout=subprocess.DEVNULL,
                                          stderr=subprocess.DEVNULL, timeout=2).returncode == 0
                wait_for(audio, audio_ready, 'Audio output')
            if touch.exists():
                previous_touch = touch.read_text().strip()
                if previous_touch not in ('0', '1'):
                    previous_touch = None
                    raise RuntimeError('Unrecognized firmware touch state.')
                touch.write_text('0\n')
            game_env = dict(env, LD_LIBRARY_PATH=str(RUNTIME / 'graphics') + ':' + env['LD_LIBRARY_PATH'],
                            LIBGL_NATIVE_WAYLAND='1', LIBGL_NATIVE_OUTPUT='0', LIBGL_FB='3',
                            LIBGL_ES='2', LIBGL_FPS='0', LIBGL_NOPSA='1',
                            LIBGL_EGL='/usr/lib/libEGL.so.1', LIBGL_GLES='/usr/lib/libGLESv2.so.2',
                            AM2R_TOUCH_ON_GAMEPLAY='1')
            # The native runner otherwise searches its legacy assets/game.unx
            # layout. Select the bundled data explicitly, including spaced paths.
            game = start([str(ROOT / 'data/runner'), '-game', str(ROOT / 'data/game.unx')],
                         game_env, 'game.log', ROOT / 'data')
            if existing_audio is None:
                start([sys.executable, str(RUNTIME / 'volume-keys.py'), '--parent', str(game.pid)],
                      env, 'volume.log')
            subprocess.run([sys.executable, str(RUNTIME / 'focus-game.py'), settings['game_label']],
                           env=env, check=True, timeout=35)
            return game.wait()
        finally:
            finish()
            if previous_touch is not None:
                touch.write_text(previous_touch + '\n')

if __name__ == '__main__':
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(143))
    signal.signal(signal.SIGINT, lambda *_: sys.exit(130))
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        print('AM2ARM could not start: ' + str(error), file=sys.stderr)
        raise SystemExit(1)
