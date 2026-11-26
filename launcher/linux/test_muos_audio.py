"""Exercise the muOS audio session with firmware command and socket fixtures."""
import json
import os
from pathlib import Path
import socket
import sys
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch


class MuosAudioTests(unittest.TestCase):
    def setUp(self):
        from launcher import muos_audio
        self.audio = muos_audio
        temp = TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.work = Path(temp.name)
        self.record = self.work / 'bridge.json'
        self.log = self.work / 'audio.log'
        self.env = dict(os.environ, XDG_RUNTIME_DIR=str(self.work), PIPEWIRE_RUNTIME_DIR=str(self.work),
                        PROBE_RECORD=str(self.record), FAKE_SINK='brick-speaker')
        self.env.pop('PULSE_RUNTIME_PATH', None)
        self.env.pop('PIPEWIRE_REMOTE', None)
        self.env.pop('PULSE_SINK', None)
        self.env['PULSE_SERVER'] = 'unix:' + str(self.work / 'shared')
        self.socket('pipewire-0')
        pactl = self.program('pactl', """
from pathlib import Path
import sys
path = Path(sys.argv[2].removeprefix('unix:'))
if sys.argv[1] != '-s' or not path.is_socket():
    sys.exit(1)
sinks = path.with_suffix('.sinks').read_text().splitlines()
if sys.argv[3:] == ['list', 'short', 'sinks']:
    for index, sink in enumerate(sinks):
        print(f'{index}\\t{sink}\\tPipeWire')
elif sys.argv[3:] == ['get-default-sink']:
    print(sinks[-1])
else:
    sys.exit(2)
""")
        bridge = self.program('pipewire-pulse', """
import json, os, signal, socket
from pathlib import Path
path = Path(os.environ['PULSE_RUNTIME_PATH']) / 'native'
peer = socket.socket(socket.AF_UNIX)
path.with_suffix('.sinks').write_text(os.environ['FAKE_SINK'])
Path(os.environ['PROBE_RECORD']).write_text(json.dumps([os.getpid(), os.environ['PIPEWIRE_RUNTIME_DIR'],
    os.environ.get('LD_LIBRARY_PATH'), os.environ.get('LD_PRELOAD')]))
peer.bind(str(path))
while True:
    signal.pause()
""")
        for key, value in [('PACTL', pactl), ('PIPEWIRE_PULSE', bridge), ('SYSTEM_RUNTIME', self.work),
                           ('START_TIMEOUT', 0.7)]:
            self.enterContext(patch.object(self.audio, key, value))

    def program(self, name, source):
        path = self.work / name
        path.write_text('#!' + sys.executable + '\n' + source)
        path.chmod(0o700)
        return path

    def socket(self, name):
        sock = socket.socket(socket.AF_UNIX)
        self.addCleanup(sock.close)
        sock.bind(str(self.work / name))

    def session(self):
        return self.audio.prepare_muos_audio(self.env, self.work, self.log)

    def test_reuses_default_real_sink_and_preserves_external_server(self):
        self.socket('shared')
        (self.work / 'shared.sinks').write_text('auto_null\nheadphones\nbrick-speaker')
        before = self.env.copy()
        with self.session():
            self.assertEqual(self.env['PULSE_SERVER'], before['PULSE_SERVER'])
            self.assertEqual(self.env['PULSE_SINK'], 'brick-speaker')
        self.assertEqual(self.env, before)
        self.assertFalse(self.record.exists())
        self.assertTrue((self.work / 'shared').is_socket())

    def test_null_sink_starts_private_bridge_and_restores_env_on_exception(self):
        self.socket('shared')
        (self.work / 'shared.sinks').write_text('auto_null')
        self.env.update(LD_LIBRARY_PATH='/bundle/lib', LD_PRELOAD='/bundle/libcrusty.so')
        before = self.env.copy()
        with self.assertRaisesRegex(RuntimeError, 'game exited'):
            with self.session():
                server = Path(self.env['PULSE_SERVER'].removeprefix('unix:'))
                self.assertTrue(server.is_socket())
                self.assertEqual(server.parent.stat().st_mode & 0o777, 0o700)
                self.assertEqual(self.env['PULSE_SINK'], 'brick-speaker')
                pid, graph, libpath, preload = json.loads(self.record.read_text())
                self.assertEqual((graph, libpath, preload), (str(self.work), None, None))
                raise RuntimeError('game exited')
        self.assertEqual(self.env, before)
        with self.assertRaises(ProcessLookupError):
            os.kill(pid, 0)
        self.assertTrue((self.work / 'shared').is_socket())
        self.assertFalse(server.exists())

    def test_private_server_without_sink_is_reaped_and_reported(self):
        self.env['FAKE_SINK'] = 'auto_null'
        before = self.env.copy()
        with self.assertRaisesRegex(RuntimeError, 'sink'):
            with self.session():
                self.fail('game started with a null sink')
        self.assertEqual(self.env, before)
        pid = json.loads(self.record.read_text())[0]
        with self.assertRaises(ProcessLookupError):
            os.kill(pid, 0)

    def test_missing_graph_does_not_start_bridge(self):
        (self.work / 'pipewire-0').unlink()
        before = self.env.copy()
        with self.assertRaisesRegex(RuntimeError, 'PipeWire audio socket'):
            with self.session():
                self.fail('game started without an audio server')
        self.assertEqual(self.env, before)
        self.assertFalse(self.record.exists())


if __name__ == '__main__':
    unittest.main()
