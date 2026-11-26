"""Check the private dArkOS audio process and the offline packer's trust boundary."""
import hashlib
import os
from pathlib import Path
import socket
import sys
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch


class DarkosAudioTests(unittest.TestCase):
    def setUp(self):
        from launcher import darkos_audio
        self.audio = darkos_audio
        temp = TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        self.work = self.root / 'session'
        self.work.mkdir()
        self.bundle = self.root / 'card'
        files = {
            'bin/pulseaudio': """import os, signal, socket
from pathlib import Path
s = socket.socket(socket.AF_UNIX); s.bind(os.environ['PULSE_SERVER'][5:])
print(os.getpid(), flush=True)
signal.pause()
""",
            'bin/pactl': """import os
from pathlib import Path
if Path(os.environ['PULSE_SERVER'][5:]).is_socket():
    print('am2arm')
""",
        }
        self.hashes = {}
        for name, contents in files.items():
            path = self.bundle / name
            path.parent.mkdir(parents=True, exist_ok=True)
            data = contents.encode()
            path.write_bytes(data)
            path.chmod(0o600)
            self.hashes[name] = hashlib.sha256(data).hexdigest()
        loader = self.root / 'loader'
        loader.write_text(f'#!{sys.executable}\nimport os, sys\nos.execv(sys.executable, [sys.executable, *sys.argv[3:]])\n')
        loader.chmod(0o700)
        for name, value in [('LOADER', loader), ('BUNDLE', self.bundle), ('FILES', self.hashes)]:
            patcher = patch.object(self.audio, name, value)
            patcher.start()
            self.addCleanup(patcher.stop)

    def test_private_server_exits_and_restores_environment_when_game_raises(self):
        env = {'PULSE_COOKIE': 'previous-cookie', 'PULSE_SINK': 'previous-sink', 'PATH': ''}
        original = dict(env)
        log = self.root / 'audio.log'
        with self.assertRaisesRegex(RuntimeError, 'game ended'):
            with self.audio.prepare_darkos_audio(env, self.work, log):
                socket = Path(env['PULSE_SERVER'][5:])
                self.assertTrue(socket.is_socket())
                self.assertEqual(0o600, Path(env['PULSE_COOKIE']).stat().st_mode & 0o777)
                self.assertEqual('am2arm', env['PULSE_SINK'])
                pid = int(log.read_text().strip())
                raise RuntimeError('game ended')
        self.assertEqual(original, env)
        self.assertFalse(socket.exists())
        with self.assertRaises(ProcessLookupError):
            os.kill(pid, 0)

    def test_corrupt_card_copy_is_rejected_before_changing_environment(self):
        (self.bundle / 'bin/pulseaudio').write_bytes(b'truncated')
        env = {'PULSE_SINK': 'original'}
        with self.assertRaisesRegex(RuntimeError, 'pulseaudio'):
            with self.audio.prepare_darkos_audio(env, self.work, self.root / 'audio.log'):
                self.fail('A corrupted daemon was started')
        self.assertEqual({'PULSE_SINK': 'original'}, env)
        self.assertEqual([], list(self.work.iterdir()))

    def test_failed_server_start_preserves_environment_and_removes_staging(self):
        daemon = self.bundle / 'bin/pulseaudio'
        daemon.write_text('raise SystemExit(1)\n')
        self.hashes['bin/pulseaudio'] = hashlib.sha256(daemon.read_bytes()).hexdigest()
        env = {'PULSE_COOKIE': 'original'}
        with self.assertRaisesRegex(RuntimeError, 'ALSA'):
            with self.audio.prepare_darkos_audio(env, self.work, self.root / 'audio.log'):
                self.fail('A failed daemon reached the game')
        self.assertEqual({'PULSE_COOKIE': 'original'}, env)
        self.assertEqual([], list(self.work.iterdir()))

    def test_running_firmware_server_is_reused(self):
        backend = self.root / 'native'
        with socket.socket(socket.AF_UNIX) as server:
            server.bind(str(backend))
            env = {'PULSE_SERVER': 'unix:' + str(backend), 'PULSE_COOKIE': 'existing'}
            original = dict(env)
            log = self.root / 'audio.log'
            with self.audio.prepare_darkos_audio(env, self.work, log):
                self.assertEqual(original, env)
                self.assertFalse(log.exists())
        self.assertEqual(original, env)

    def test_private_server_replaces_remote_server_without_contacting_it(self):
        pactl = self.bundle / 'bin/pactl'
        probes = self.root / 'probes'
        pactl.write_text(f"import os\nwith open({str(probes)!r}, 'a') as output:\n"
                         "    print(os.environ['PULSE_SERVER'], file=output)\nprint('am2arm')\n")
        self.hashes['bin/pactl'] = hashlib.sha256(pactl.read_bytes()).hexdigest()
        env = {'PULSE_SERVER': 'tcp:192.0.2.1'}
        with self.audio.prepare_darkos_audio(env, self.work, self.root / 'audio.log'):
            self.assertTrue(env['PULSE_SERVER'].startswith('unix:/'))
        self.assertTrue(all(line.startswith('unix:/') for line in probes.read_text().splitlines()))
        self.assertEqual({'PULSE_SERVER': 'tcp:192.0.2.1'}, env)


class DarkosBundleTests(unittest.TestCase):
    def test_corrupted_bundle_is_rejected_before_reading_members(self):
        from darkos_audio_bundle import read_bundle
        with TemporaryDirectory() as tmp:
            path = Path(tmp) / 'bad.zip'
            path.write_bytes(b'not the verified archive')
            with self.assertRaisesRegex(ValueError, 'digest|checksum|SHA-256'):
                read_bundle(path)
