"""Give the GameMaker runner a PulseAudio connection to the muOS PipeWire graph."""
from contextlib import contextmanager, ExitStack
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory
import time


PACTL = '/usr/bin/pactl'
PIPEWIRE_PULSE = '/usr/bin/pipewire-pulse'
SYSTEM_RUNTIME = Path('/run')
START_TIMEOUT = 8


def pulse_output(server, env, *arguments):
    try:
        result = subprocess.run([PACTL, '-s', server, *arguments], env=env,
                                stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                                text=True, errors='replace', timeout=2)
    except subprocess.TimeoutExpired:
        return ''
    return result.stdout.strip() if result.returncode == 0 else ''


def usable_sink(server, env):
    sinks = []
    for row in pulse_output(server, env, 'list', 'short', 'sinks').splitlines():
        fields = row.split('\t')
        if len(fields) >= 2 and fields[1] and fields[1] != 'auto_null':
            sinks.append(fields[1])
    if not sinks:
        return ''
    preferred = env.get('PULSE_SINK')
    if preferred in sinks:
        return preferred
    if len(sinks) > 1:
        default = pulse_output(server, env, 'get-default-sink')
        if default in sinks:
            return default
    return sinks[0]


def stop_bridge(process):
    if process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=2)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()


@contextmanager
def prepare_muos_audio(env, work, log):
    """Set the game's Pulse server and sink for the lifetime of this context."""
    firmware = env.copy()
    firmware.pop('LD_PRELOAD', None)
    firmware.pop('LD_LIBRARY_PATH', None)
    xdg = Path(firmware.get('XDG_RUNTIME_DIR') or SYSTEM_RUNTIME)
    pulse_dir = Path(firmware.get('PULSE_RUNTIME_PATH') or xdg / 'pulse')
    servers = (firmware.get('PULSE_SERVER'), 'unix:' + str(pulse_dir / 'native'),
               'unix:' + str(SYSTEM_RUNTIME / 'pulse' / 'native'))
    with ExitStack() as resources:
        for server in dict.fromkeys(servers):
            if server and (sink := usable_sink(server, firmware)):
                break
        else:
            remote = firmware.get('PIPEWIRE_REMOTE') or 'pipewire-0'
            roots = (Path(firmware.get('PIPEWIRE_RUNTIME_DIR') or xdg), xdg, SYSTEM_RUNTIME)
            native = next((root / remote for root in roots if (root / remote).is_socket()), None)
            if native is None:
                raise RuntimeError('The muOS PipeWire audio socket is unavailable.')
            private = Path(resources.enter_context(TemporaryDirectory(prefix='pulse-', dir=work)))
            socket = private / 'native'
            server = 'unix:' + str(socket)
            bridge_env = dict(firmware, PIPEWIRE_RUNTIME_DIR=str(native.parent), PIPEWIRE_REMOTE=native.name,
                              PULSE_RUNTIME_PATH=str(private), HOME=str(private),
                              XDG_CONFIG_HOME=str(private / 'config'), XDG_STATE_HOME=str(private / 'state'))
            stream = resources.enter_context(Path(log).open('w'))
            process = subprocess.Popen([PIPEWIRE_PULSE], env=bridge_env, stdin=subprocess.DEVNULL,
                                       stdout=stream, stderr=subprocess.STDOUT, start_new_session=True)
            resources.callback(stop_bridge, process)
            deadline = time.monotonic() + START_TIMEOUT
            while process.poll() is None:
                if socket.is_socket() and (sink := usable_sink(server, firmware)):
                    break
                if time.monotonic() >= deadline:
                    raise RuntimeError(f'The muOS audio bridge could not reach a playback sink. See {log}.')
                time.sleep(0.1)
            else:
                raise RuntimeError(f'The muOS audio bridge exited with status {process.returncode}. See {log}.')
        before = {key: env.get(key) for key in ('PULSE_SERVER', 'PULSE_SINK')}
        env.update(PULSE_SERVER=server, PULSE_SINK=sink)
        try:
            print(f'Using muOS audio sink {sink}', flush=True)
            yield
        finally:
            for key, previous in before.items():
                if previous is None:
                    env.pop(key, None)
                else:
                    env[key] = previous
