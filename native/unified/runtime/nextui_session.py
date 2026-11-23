"""Start and supervise the installer or game on direct-display firmware."""
from pathlib import Path
import fcntl
from contextlib import ExitStack
import hashlib
import importlib.util
import json
import os
import platform
import resource
import shutil
import signal
import struct
import subprocess
import sys
import tempfile
import time
import xml.etree.ElementTree as ET

from nextui_layout import installed_game, stock_save_directory
from compat_display import (AMBERELEC_PANELS, EGL_NAMES, GLES_NAMES, KMS_PANELS, SDL_NAMES,
                            library_candidates, library_dirs, read, video_drivers)
from nextui_controls import brick_mappings, evdev_mapping
from brick_rumble import BrickRumble
from spruce_exit import SpruceMenuExit
from trimui_device import current_device, display_size
from weston_graphics import WestonpackRequired, locate_graphics

RUNTIME = Path(__file__).resolve().parent
ROOT = RUNTIME.parent
CARD = Path(os.environ.get('AM2ARM_GAME_CARD') or ROOT.parent)
CHILDREN = []


def command(binary, arguments=(), extra=(), preload=None):
    core = RUNTIME/'core'
    # AmberELEC's SDL requires its glibc, and its libcurl requires its OpenSSL.
    firmware_abi = os.environ.get('AM2ARM_DEVICE_PROFILE') in AMBERELEC_PANELS
    loader = (Path('/usr/lib') if firmware_abi else core)/'ld-linux-aarch64.so.1'
    providers = list(map(Path, extra))
    bundled = RUNTIME/'lib'
    directories = providers + [bundled] if firmware_abi else [core, bundled, *providers]
    directories.extend(Path(value) for value in os.environ.get('LD_LIBRARY_PATH', '').split(':')
                       if value and (not firmware_abi or Path(value) != core))
    directories.extend([Path('/usr/trimui/lib'), Path('/usr/lib'), Path('/lib')])
    path = ':'.join(map(str, dict.fromkeys(directories)))
    result = [str(loader), '--library-path', path]
    if preload:
        result += ['--preload', str(preload)]
    return result+[str(binary)]+list(map(str, arguments))


def python(script, *arguments, extra=()):
    return command(RUNTIME/'python/usr/bin/python3.11', [script, *arguments], extra=extra)


def start(arguments, env, log, cwd=None):
    with log.open('w') as output:
        process = subprocess.Popen(arguments, env=env, cwd=cwd, stdout=output,
                                   stderr=subprocess.STDOUT, start_new_session=True)
    CHILDREN.append(process)
    return process


def cleanup():
    for process in reversed(CHILDREN):
        if process.poll() is None:
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=4)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait(timeout=2)


def wait_ready(process, predicate, description, timeout=20):
    deadline = time.monotonic()+timeout
    while not predicate():
        if process.poll() is not None:
            raise RuntimeError(description+' exited. Please send the logs folder.')
        if time.monotonic() >= deadline:
            raise RuntimeError(description+' did not become ready. Please send the logs folder.')
        time.sleep(.05)


def prepare_amber_audio(env, work, log):
    def default_sink():
        try:
            result = subprocess.run(['pactl', 'get-default-sink'], text=True, stdout=subprocess.PIPE,
                                    stderr=subprocess.DEVNULL, timeout=2,
                                    env=dict(env, LD_LIBRARY_PATH='/usr/lib/pulseaudio'))
        except subprocess.TimeoutExpired:
            return ''
        return result.stdout.strip() if result.returncode == 0 else ''

    if env.get('PULSE_SERVER') and default_sink() not in ('', 'auto_null'):
        print('Audio output: firmware PulseAudio', flush=True)
        return

    # AmberELEC normally stops PulseAudio and leaves ALSA's default PCM available.
    # GameMaker needs a working PulseAudio device through its final shutdown.
    runtime, state = work/'pulse-run', work/'pulse-state'
    socket, cookie = work/'audio', work/'pulse-cookie'
    runtime.mkdir(mode=0o700)
    state.mkdir(mode=0o700)
    cookie.touch(mode=0o600, exist_ok=False)
    cookie.write_bytes(os.urandom(256))
    env.update(PULSE_RUNTIME_PATH=str(runtime), PULSE_STATE_PATH=str(state), PULSE_COOKIE=str(cookie),
               PULSE_SERVER='unix:' + str(socket), PULSE_SINK='am2arm')
    server_env = dict(env, HOME=str(work), XDG_CONFIG_HOME=str(work), LD_LIBRARY_PATH='/usr/lib/pulseaudio')
    audio = start(['pulseaudio', '-n', '--daemonize=no', '--use-pid-file=no', '--exit-idle-time=-1',
                   '--disable-shm=yes', '--fail=yes', '--log-target=stderr',
                   '-L', f'module-native-protocol-unix socket={socket} auth-cookie={cookie}',
                   '-L', 'module-alsa-sink sink_name=am2arm device=default rate=44100 channels=2 tsched=0'],
                  server_env, log)
    wait_ready(audio, lambda: socket.is_socket() and default_sink() == 'am2arm', 'ALSA audio output', timeout=8)
    print('Audio output: private PulseAudio on AmberELEC ALSA', flush=True)


def check(env, *args):
    try:
        providers = [Path(args[1]).parent]
        providers.extend(Path(env[k]).parent for k in ('SDL_VIDEO_GL_DRIVER', 'SDL_VIDEO_EGL_DRIVER') if k in env)
        result = subprocess.run(python(RUNTIME/'sdl_check.py', *args, extra=providers), env=env,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                text=True, errors='replace', timeout=8)
    except subprocess.TimeoutExpired:
        print('Video check timed out:', *args, flush=True)
        return ''
    print(result.stdout.strip(), flush=True)
    return result.stdout if result.returncode == 0 else ''


def display_options(device, env, needs_gles):
    folders = library_dirs(CARD, device)
    if device == 'flip' and 'my355' in read('/etc/os-release').lower():
        folders = list(dict.fromkeys([Path('/usr/lib'), *folders]))
    sdls = library_candidates(folders, SDL_NAMES)
    if not sdls:
        raise RuntimeError('Could not locate a 64-bit firmware SDL2 library.')
    egls = library_candidates(folders, EGL_NAMES)
    gles = library_candidates(folders, GLES_NAMES)
    for sdl in sdls:
        lines = check(env, 'drivers', sdl).splitlines()
        names = next((json.loads(l[8:]) for l in lines if l.startswith('DRIVERS ')), [])
        for driver in video_drivers(device, names):
            if not needs_gles:
                yield sdl, driver, None, None
                continue
            for egl in egls:
                for gl in sorted(gles, key=lambda p: p.parent != egl.parent):
                    trial = dict(env, SDL_VIDEO_EGL_DRIVER=str(egl), SDL_VIDEO_GL_DRIVER=str(gl))
                    if (device in KMS_PANELS or device == 'flip') and driver.lower() == 'kmsdrm':
                        trial['EGL_PLATFORM'] = 'gbm'
                    print('Testing GLES:', driver, sdl, egl, gl, flush=True)
                    if check(trial, 'gles', sdl, driver, *display_size(device)):
                        yield sdl, driver, egl, gl
                        return
    if needs_gles and (not egls or not gles):
        raise RuntimeError('Could not locate both ARM64 firmware EGL and GLESv2 libraries.')


def report(device):
    details = {'package': 'AM2ARM 1.6.3', 'menu': os.environ.get('AM2ARM_MENU_NAME'),
               'spruce': (CARD/'spruce').is_dir(),
               'device': device, 'display': display_size(device),
               'machine': platform.machine(),
               'kernel': platform.release(), 'firmware': {}, 'input': []}
    for label, file in [('model', Path('/proc/device-tree/model')),
                        ('os', Path('/etc/os-release')),
                        ('stock-version', Path('/etc/version')),
                        ('crossmix-version', Path('/usr/trimui/crossmix-version.txt')),
                        ('nextui-version', CARD/'.system/version.txt'),
                        ('nextui-build', CARD/'.system/tg5040/version.txt')]:
        try:
            details['firmware'][label] = file.read_text()[:4096].rstrip('\0\n')
        except OSError:
            pass
    for entry in Path('/sys/class/input').glob('event*'):
        record = {'event': entry.name}
        for field in ('name', 'capabilities/key', 'capabilities/abs', 'id/bustype',
                      'id/vendor', 'id/product', 'id/version'):
            try:
                record[field] = (entry/'device'/field).read_text().strip()
            except OSError:
                pass
        details['input'].append(record)
    (ROOT/'logs/device.json').write_text(json.dumps(details, indent=2)+'\n')


def game_options(game, device='brick'):
    metadata = json.loads((game/'edition.json').read_text())
    spec = importlib.util.spec_from_file_location('game_launch', game/'runtime/launch.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    native = Path.home()/'.config'/metadata['game_name']
    options = native
    if os.environ.get('AM2ARM_FRONTEND') == 'stock':
        options = stock_save_directory(CARD, game)
        module.bind_save_directory(native, options)
    options.mkdir(parents=True, exist_ok=True)
    config = options/'config.ini'
    if hasattr(module, 'prepare_display_config'):
        module.prepare_display_config(config, metadata['edition'], True)
    elif not config.exists():
        # Older installed games read the legacy keys directly.
        wide = int(device in ('smartpro', 'smartpros'))
        config.write_text(f'[Screen]\nFullscreen=0\nScale=2\nWidescreen={wide}\nAspectRatio={wide}\nNano=0\n')
    mappings = (game/'data/gamecontrollerdb.txt').read_text()
    if device in ('smartpro', 'brick'):
        mappings += '\n'+brick_mappings(device)
    else:
        mappings += '\n'+evdev_mapping(device)
    module.prepare_controller_database(options, mappings)
    print('Save folder:', options, flush=True)
    return options, metadata


def prepare_rumble(game):
    folder = RUNTIME/'rumble'
    manifest = folder/'library.json'
    if not manifest.is_file():
        return False
    hashes = json.loads(manifest.read_text())
    source = folder/'libAM2ARMHaptics.so'
    target = game/'data/libAM2ARMHaptics.so'
    digest = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    if digest(source) != hashes['brick']:
        raise RuntimeError('The Brick vibration library is incomplete.')
    existing = digest(target)
    if existing != hashes['brick']:
        if existing != hashes['original']:
            print('Keeping a modified vibration library.', flush=True)
            return False
        backup = game/'state/original-haptics.so'
        backup.parent.mkdir(parents=True, exist_ok=True)
        if not backup.exists():
            shutil.copy2(target, backup)
        temporary = target.with_suffix('.new')
        shutil.copy2(source, temporary)
        temporary.replace(target)
    return True


def run(mode, device):
    if mode not in ('patcher', 'game'):
        raise RuntimeError('Unknown launch mode.')
    width, height = display_size(device)
    report(device)
    print('Hardware profile:', device, 'Screen:', f'{width}x{height}', flush=True)
    stamp = time.strftime('%Y%m%d-%H%M%S')+'-'+str(os.getpid())
    logs = ROOT/'logs'
    if mode == 'game':
        game = Path(os.environ['AM2ARM_PLAY_DIR']) if os.environ.get('AM2ARM_PLAY_DIR') else installed_game(CARD)
    temp_root = '/tmp' if device in AMBERELEC_PANELS else None
    with tempfile.TemporaryDirectory(prefix='am2arm-nextui-', dir=temp_root) as temporary, ExitStack() as resources:
        work = Path(temporary)
        rumble = None
        menu_exit = None
        number = next((i for i in range(40, 80) if not Path(f'/tmp/.X{i}-lock').exists()
                       and not Path(f'/tmp/.X11-unix/X{i}').exists()), None)
        if number is None:
            raise RuntimeError('No private input display is available.')
        cookie = os.urandom(16)
        authority = work/'Xauthority'
        fields = [b'', str(number).encode(), b'MIT-MAGIC-COOKIE-1', cookie]
        authority.write_bytes(struct.pack('>H', 65535)+b''.join(struct.pack('>H', len(f))+f for f in fields))
        authority.chmod(0o600)
        env = dict(os.environ, DISPLAY=f':{number}', XAUTHORITY=str(authority),
                   XLOCALEDIR=str(RUNTIME/'share/X11/locale'), XMODIFIERS='@im=none',
                   AM2ARM_TRIMUI_DEVICE=device)
        fonts = ET.Element('fontconfig')
        ET.SubElement(fonts, 'dir').text = str(ROOT/'patcher/assets')
        ET.SubElement(fonts, 'cachedir').text = str(work/'font-cache')
        font_config = work/'fonts.conf'
        ET.ElementTree(fonts).write(font_config, encoding='utf-8', xml_declaration=True)
        env['FONTCONFIG_FILE'] = str(font_config)
        env['FONTCONFIG_PATH'] = str(work)
        env.pop('LD_PRELOAD', None)
        env.pop('LD_LIBRARY_PATH', None)
        for key in ('WAYLAND_DISPLAY', 'SDL_VIDEODRIVER', 'SDL_RENDER_DRIVER', 'AM2ARM_PRESENT_DRIVER',
                    'AM2ARM_PRESENT_DISPLAY', 'SDL_VIDEO_EGL_DRIVER', 'SDL_VIDEO_GL_DRIVER', 'EGL_PLATFORM'):
            env.pop(key, None)
        candidates = display_options(device, env, mode == 'game')
        xserver = start(command(RUNTIME/'bin/Xvfb', [env['DISPLAY'], '-screen', '0', f'{width}x{height}x24',
            '-nolisten', 'tcp', '-auth', authority, '-xkbdir', RUNTIME/'share/X11/xkb',
            '-fp', 'built-ins', '-noreset']), env, logs/(stamp+'-display.log'), RUNTIME/'bin')
        wait_ready(xserver, lambda: Path(f'/tmp/.X11-unix/X{number}').is_socket(), 'Input display')
        if mode == 'patcher':
            if (device in ('brick', 'smartpro') and env.get('AM2ARM_FIRST_RUN') == '1'
                    and not env.get('AM2ARM_DISPLAY_NOTICE')):
                try:
                    locate_graphics(CARD, RUNTIME, os.environ)
                except WestonpackRequired:
                    env['AM2ARM_DISPLAY_NOTICE'] = 'westonpack'
            env.update(TCL_LIBRARY=str(RUNTIME/'python/usr/share/tcltk/tcl8.6'),
                       TK_LIBRARY=str(RUNTIME/'python/usr/share/tcltk/tk8.6'),
                       AM2ARM_PRESENT_READY=str(work/'visible'))
            for index, (sdl, driver, _, _) in enumerate(candidates):
                env.update(AM2ARM_FIRMWARE_SDL=str(sdl), AM2ARM_PRESENT_DRIVER=driver)
                if device in KMS_PANELS:
                    env['EGL_PLATFORM'] = 'gbm'
                logfile = logs/(stamp+f'-presentation-{index}.log')
                view = start(python(RUNTIME/'nextui_present.py', extra=library_dirs(CARD, device)), env, logfile)
                try:
                    wait_ready(view, lambda: (work/'visible').is_file(), 'Installer display', timeout=8)
                    print('Installer frame submitted:', driver, sdl, flush=True)
                    break
                except RuntimeError:
                    if view.poll() is None:
                        view.kill()
                        view.wait(timeout=3)
                    print('Presentation failed:', driver, logfile.read_text(errors='replace')[-450:], flush=True)
                    (work/'visible').unlink(missing_ok=True)
            else:
                raise RuntimeError('No firmware SDL driver could present the installer.')
            app = start(python(RUNTIME/'nextui_gui.py'), env, logs/(stamp+'-installer.log'), ROOT/'patcher')
        else:
            candidate = next(candidates, None)
            if candidate is None:
                raise RuntimeError('No firmware driver could present a GLES2 frame.')
            sdl, driver, egl, gles = candidate
            options, metadata = game_options(game, device)
            if device in AMBERELEC_PANELS:
                resources.callback(cleanup)
                prepare_amber_audio(env, work, logs/(stamp+'-audio.log'))
            if device in ('smartpro', 'brick') and prepare_rumble(game):
                mapping = brick_mappings(device).partition(',')[0]
                if len(mapping) == 32:
                    try:
                        rumble = resources.enter_context(BrickRumble(work/'rumble.sock'))
                        env.update(AM2ARM_RUMBLE_SOCKET=str(work/'rumble.sock'),
                                   AM2ARM_RUMBLE_GUID=mapping)
                        print('TrimUI vibration enabled.', flush=True)
                    except OSError as error:
                        print('TrimUI vibration unavailable:', error, flush=True)
            print('Starting Standard:', driver, 'SDL:', sdl, 'EGL:', egl, 'GLES:', gles, flush=True)
            aliases = work/'graphics'
            aliases.mkdir()
            for name, source in [('libEGL.so', egl), ('libEGL.so.1', egl),
                                 ('libGLESv2.so', gles), ('libGLESv2.so.2', gles),
                                 ('libSDL2-2.0.so.0', sdl)]:
                (aliases/name).symlink_to(source)
            env.update(CRUSTY_LIBEGL=str(egl), CRUSTY_LIBSDL=str(sdl), CRUSTY_GL4ES='1',
                       CRUSTY_WLMODE='0', CRUSTY_RESOLUTION=f'{width}x{height}', CRUSTY_SHOW_CURSOR='0',
                       SDL_AUDIODRIVER='alsa', XDG_SESSION_TYPE='x11',
                       LIBGL_ES='2', LIBGL_GL='21', LIBGL_NOPSA='1', LIBGL_GLES=str(gles),
                       LIBGL_NATIVE_WAYLAND='1',
                       ALSOFT_DRIVERS='alsa', AM2ARM_SAVE_DIR=str(options), AM2ARM_BROWSE_DIR=str(CARD))
            env.pop('WAYLAND_DISPLAY', None)
            env.update(SDL_VIDEO_EGL_DRIVER=str(egl), SDL_VIDEO_GL_DRIVER=str(gles))
            if (device in KMS_PANELS or device == 'flip') and driver.lower() == 'kmsdrm':
                env.update(EGL_PLATFORM='gbm')
            else:
                env.pop('EGL_PLATFORM', None)
            # The runner uses its own SDL for input. Only the display adapter
            # receives the firmware SDL implementation.
            use_kms = driver.lower() == 'kmsdrm' and (device in KMS_PANELS or
                      (device == 'flip' and egl == Path('/usr/lib/libEGL.so.1').resolve()))
            if use_kms:
                graphics, preload = RUNTIME/'kms', None
                for key in ('LIBGL_NATIVE_WAYLAND', 'CRUSTY_WLMODE', 'CRUSTY_GL4ES'):
                    env.pop(key, None)
                env.update(AM2ARM_STOCK_DISPLAY='1', LIBGL_FB='3', LIBGL_EGL=str(egl),
                           SDL_VIDEODRIVER='x11')
                if device in KMS_PANELS:
                    # Keep the Mali driver's C++ allocations and frees on the runner's allocator.
                    env.update(AM2ARM_FIRMWARE_SDL=str(sdl), AM2ARM_KMS_SIZE=f'{width}x{height}',
                               LIBGL_DEEPBIND='0')
                print('Game output: native SDL KMSDRM', flush=True)
            else:
                graphics = locate_graphics(CARD, RUNTIME, os.environ)
                preload = graphics/'libcrusty.so'
                print('Game output: Crusty with firmware SDL auto-selection', flush=True)
            app = start(command(game/'data/runner', ['-game', game/'data/game.unx'],
                extra=(graphics, aliases, game/'runtime/lib', sdl.parent, egl.parent, gles.parent),
                preload=preload), env, logs/(stamp+'-game.log'), game/'data')
            if device == 'smartpros' and env.get('AM2ARM_FRONTEND') == 'spruce':
                watch = SpruceMenuExit.open(CARD)
                if watch is not None:
                    menu_exit = resources.enter_context(watch)
            start(python(game/'runtime/focus-game.py', metadata['game_label']), env,
                  logs/(stamp+'-focus.log'))
        while app.poll() is None:
            if xserver.poll() is not None or (mode == 'patcher' and view.poll() is not None):
                raise RuntimeError('The display stopped while running. Please send the logs folder.')
            if menu_exit and menu_exit.requested():
                # Deliver the normal window-manager close to the game on its own X server.
                with (logs/(stamp+'-close.log')).open('a') as output:
                    try:
                        result = subprocess.run(python(game/'runtime/focus-game.py', metadata['game_label'], '--close'),
                                                env=env, stdout=output, stderr=subprocess.STDOUT, timeout=6)
                        print('Menu close request status:', result.returncode, flush=True)
                    except (OSError, subprocess.TimeoutExpired) as error:
                        print('Menu close request failed:', error, flush=True)
            if rumble:
                rumble.poll()
            else:
                time.sleep(.25)
        print('Application exit status:', app.returncode, flush=True)
        if app.returncode:
            log = logs/(stamp+('-game.log' if mode == 'game' else '-installer.log'))
            print(log.read_text(errors='replace')[-1100:], flush=True)
        return app.returncode


def main():
    resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
    def stop(*_):
        raise KeyboardInterrupt
    signal.signal(signal.SIGINT, stop)
    signal.signal(signal.SIGTERM, stop)
    with open('/tmp/am2arm-nextui.lock', 'a') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print('AM2ARM is already open.', flush=True)
            return 1
        try:
            awake = Path('/tmp/stay_awake')
            owns_awake = False
            device = os.environ.get('AM2ARM_DEVICE_PROFILE') or current_device()
            if (os.environ.get('AM2ARM_FRONTEND') == 'stock' or (CARD/'spruce').is_dir()) and device in ('smartpro', 'smartpros', 'brick'):
                try:
                    with awake.open('x') as stream:
                        stream.write('1\n')
                    owns_awake = True
                except FileExistsError:
                    pass
            try:
                return run(sys.argv[1] if len(sys.argv) > 1 else 'patcher', device)
            finally:
                if owns_awake:
                    awake.unlink(missing_ok=True)
        except WestonpackRequired as error:
            print(error, flush=True)
            return 78
        except (RuntimeError, OSError, ValueError) as error:
            print('Could not start:', error, flush=True)
            return 1
        except KeyboardInterrupt:
            return 130
        finally:
            cleanup()


if __name__ == '__main__':
    raise SystemExit(main())
