"""Start the G350's private PulseAudio server against dArkOS's default ALSA PCM."""
from contextlib import contextmanager
import hashlib
import os
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory
import time


BUNDLE = Path(__file__).resolve().parent / 'darkos-audio'
LOADER = Path('/usr/lib/ld-linux-aarch64.so.1')
MULTIARCH = Path('/usr/lib/aarch64-linux-gnu')
FILES = {
    'bin/pactl': 'eee194910295c361a17944ea6601ff433d5b4791fa96092bca435128df710b3a',
    'bin/pulseaudio': 'beac3e8d5ae20b9bfb26304541d42eca45ac58e97b6e38892a001870da6e6ade',
    'lib/liborc-0.4.so.0': '74b933f64f1b9c5578223b6044d1baf0c6281c57b9dc86f3c4a434d2d03609c4',
    'lib/libpulsecore-17.0.so': 'da0e9bb8023e68013674c2286110a3f1e6ecc0411fbaa8913e0adb919b6dc918',
    'modules/libalsa-util.so': 'bf7bfe5e4fcd443b4e818c13b2c5fa4cbb65475124340582ec4b418e7c3afac2',
    'modules/libprotocol-native.so': 'c8e3eb97c40b121c0367542f200157ab6654c5bc4853784712e96137d5448c64',
    'modules/module-alsa-sink.so': 'eb5a88395740ba06ebc9d8b0c3b8cd969d8a36e916001468bb8a281dec680550',
    'modules/module-native-protocol-unix.so': 'e89a35387901b8f4b3f1b21bebbe7100355c4d3269e1e8bf22db472e06cecf49',
}


def default_sink(pactl, env):
    try:
        result = subprocess.run([*pactl, 'get-default-sink'], env=env, capture_output=True,
                                text=True, timeout=2)
    except subprocess.TimeoutExpired:
        return ''
    return result.stdout.strip() if result.returncode == 0 else ''


@contextmanager
def prepare_darkos_audio(env, work, log):
    """Use the firmware's live Pulse server or keep a private one alive until game exit."""
    with TemporaryDirectory(prefix='audio-', dir=work) as directory:
        root = Path(directory)
        # Loading from session storage also works when files on the games card lack exec bits.
        for name, digest in FILES.items():
            data = (BUNDLE / name).read_bytes()
            if hashlib.sha256(data).hexdigest() != digest:
                raise RuntimeError(f'The dArkOS audio component {name} failed verification.')
            target = root / name
            target.parent.mkdir(exist_ok=True)
            target.write_bytes(data)
            target.chmod(0o700 if name.startswith('bin/') else 0o600)

        libraries = ':'.join(map(str, (root / 'lib', root / 'modules', MULTIARCH / 'pulseaudio', MULTIARCH)))
        loader = [str(LOADER), '--library-path', libraries]
        pactl = [*loader, str(root / 'bin/pactl')]
        server_env = env.copy()
        for name in ('LD_PRELOAD', 'LD_LIBRARY_PATH'):
            server_env.pop(name, None)
        address = env.get('PULSE_SERVER', '').removeprefix('unix:')
        if (address.startswith('/') and len(address.split()) == 1 and Path(address).is_socket()
                and default_sink(pactl, server_env) not in ('', '(null)', 'auto_null')):
            yield
            return

        run, state, cookie, socket = (root / name for name in ('run', 'state', 'cookie', 'socket'))
        run.mkdir(mode=0o700)
        state.mkdir(mode=0o700)
        with cookie.open('xb') as output:
            os.fchmod(output.fileno(), 0o600)
            output.write(os.urandom(256))
        connection = {'PULSE_SERVER': 'unix:' + str(socket), 'PULSE_COOKIE': str(cookie), 'PULSE_SINK': 'am2arm'}
        server_env.update(connection, HOME=str(root), XDG_CONFIG_HOME=str(root), XDG_RUNTIME_DIR=str(run),
                          PULSE_RUNTIME_PATH=str(run), PULSE_STATE_PATH=str(state))
        server_env.pop('PULSE_SINK', None)
        arguments = [*loader, str(root / 'bin/pulseaudio'), '-n', '--daemonize=no', '--use-pid-file=no',
                     '--exit-idle-time=-1', '--disable-shm=yes', '--fail=yes', '--log-target=stderr',
                     '--dl-search-path=' + str(root / 'modules'),
                     '-L', f'module-native-protocol-unix socket={socket} auth-cookie={cookie}',
                     '-L', 'module-alsa-sink sink_name=am2arm device=default rate=44100 channels=2 tsched=0']
        with Path(log).open('w') as output:
            process = subprocess.Popen(arguments, env=server_env, stdout=output, stderr=subprocess.STDOUT)
            try:
                deadline = time.monotonic() + 8
                while process.poll() is None and time.monotonic() < deadline:
                    if socket.is_socket() and default_sink(pactl, server_env) == 'am2arm':
                        break
                    time.sleep(.05)
                else:
                    raise RuntimeError(f'dArkOS could not open the default ALSA playback device. See {log}.')
                saved = {name: env.get(name) for name in connection}
                env.update(connection)
                try:
                    yield
                finally:
                    for name, old in saved.items():
                        if old is None:
                            env.pop(name, None)
                        else:
                            env[name] = old
            finally:
                if process.poll() is None:
                    process.terminate()
                    try:
                        process.wait(timeout=3)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.wait()
