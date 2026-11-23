import os
from pathlib import Path
import socket
import struct
import subprocess
import sys
import tempfile
import threading
import unittest

SOURCE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SOURCE / 'menus'))
from launch_layout import card_shortcuts
from handheld_platform import wayland_environment
from route import choose_backend, resolve_display


class WaylandServer:
    """Only the display.sync request needed for a compositor round trip."""
    def __init__(self, path):
        self.server = socket.socket(socket.AF_UNIX)
        self.server.bind(str(path))
        self.server.listen(4)
        self.server.settimeout(.05)
        self.stopped = threading.Event()
        self.thread = threading.Thread(target=self.serve, daemon=True)

    def serve(self):
        while not self.stopped.is_set():
            try:
                client, _ = self.server.accept()
            except socket.timeout:
                continue
            with client:
                client.settimeout(1)
                with client.makefile('rb') as stream:
                    request = stream.read(12)
                if len(request) == 12:
                    obj, header, callback = struct.unpack('=III', request)
                    if obj == 1 and header == 12 << 16:
                        client.sendall(struct.pack('=III', callback, 12 << 16, 0))

    def __enter__(self):
        self.thread.start()
        return self

    def __exit__(self, *exc):
        self.stopped.set()
        self.thread.join(2)
        self.server.close()


class StandaloneRoutes(unittest.TestCase):
    def test_stale_socket_on_a_known_board_reaches_direct_fallback(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'wayland-0'
            with socket.socket(socket.AF_UNIX) as dead:
                dead.bind(str(path))
            env = {'XDG_RUNTIME_DIR': folder, 'WAYLAND_DISPLAY': path.name}
            self.assertEqual(choose_backend('ports', env, device=lambda: 'brick'), 'direct')

    def test_direct_session_carries_the_detected_profile_to_both_children(self):
        env = {'AM2ARM_DEVICE_PROFILE': 'obsolete', 'HOME': '/storage'}
        route, selected = resolve_display('spruce', env, device=lambda: 'smartpros')
        self.assertEqual(route, 'direct')
        self.assertEqual(selected['AM2ARM_DEVICE_PROFILE'], 'smartpros')
        self.assertEqual(env['AM2ARM_DEVICE_PROFILE'], 'obsolete')

    def test_unsupported_device_report_lists_evidence_without_opening_the_display(self):
        from compat_display import display_inventory
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            for name, state in [('DSI-1','connected'), ('HDMI-A-1','disconnected')]:
                entry = root/'drm'/f'card0-{name}'
                entry.mkdir(parents=True)
                (entry/'status').write_text(state+'\n')
                (entry/'modes').write_text('480x320\n320x240\n')
            libs = root/'lib'
            libs.mkdir()
            for name in ('libSDL2-2.0.so.0','libEGL.so.1','libGLESv2.so.2'):
                (libs/name).write_bytes(bytes.fromhex('7f454c460201'+'00'*10+'0300b700'))
            observed = display_inventory(root/'drm', [libs])
            self.assertEqual(observed['connected_drm'], {'card0-DSI-1':'480x320'})
            self.assertEqual(observed['arm64_libraries'], {
                'SDL2': ['libSDL2-2.0.so.0'], 'EGL': ['libEGL.so.1'], 'GLES2': ['libGLESv2.so.2']})

    def test_nondefault_compositor_is_discovered_and_handed_to_the_child(self):
        with tempfile.TemporaryDirectory() as folder:
            with WaylandServer(Path(folder) / 'wayland-3'):
                # A firmware menu may supply the runtime directory only.
                env = dict(os.environ, XDG_RUNTIME_DIR=folder, AM2ARM_FRONTEND='ports')
                env.pop('WAYLAND_DISPLAY', None)
                selected = wayland_environment(env)
                self.assertEqual((selected['XDG_RUNTIME_DIR'], selected['WAYLAND_DISPLAY']),
                                 (folder, 'wayland-3'))
                child = 'printf "%s\\n" "$AM2ARM_DISPLAY_PATH" "$XDG_RUNTIME_DIR" "$WAYLAND_DISPLAY" "$1"'
                result = subprocess.run([sys.executable, str(SOURCE/'runtime/route.py'),
                                         '--exec', '/bin/sh', '-c', child, 'probe', 'arg with spaces'],
                                        env=env, capture_output=True, text=True, timeout=4)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout.splitlines(), ['ports', folder, 'wayland-3', 'arg with spaces'])

    def test_nextui_tg5050_launches_the_same_standalone_as_the_brick(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            entries = card_shortcuts(root)
            brick = 'Tools/tg5040/AM2ARM.pak/launch.sh'
            smart_pro_s = 'Tools/tg5050/AM2ARM.pak/launch.sh'
            self.assertIn(smart_pro_s, entries)
            self.assertEqual(entries[smart_pro_s].read_bytes(), entries[brick].read_bytes())

    def test_absolute_display_keeps_the_audio_runtime_directory(self):
        with tempfile.TemporaryDirectory() as folder:
            endpoint = Path(folder)/'external'/'wayland-2'
            endpoint.parent.mkdir()
            with WaylandServer(endpoint):
                env = {'XDG_RUNTIME_DIR': folder, 'WAYLAND_DISPLAY': str(endpoint)}
                self.assertEqual(wayland_environment(env), env)

    def test_ambiguous_live_displays_require_the_firmware_session(self):
        with tempfile.TemporaryDirectory() as folder:
            with WaylandServer(Path(folder)/'wayland-1'), WaylandServer(Path(folder)/'wayland-2'):
                with self.assertRaisesRegex(RuntimeError, 'Multiple Wayland'):
                    choose_backend('ports', {'XDG_RUNTIME_DIR': folder}, device=lambda: 'brick')

    def test_roms_view_finds_only_its_own_cards_payload(self):
        with tempfile.TemporaryDirectory() as folder:
            storage = Path(folder) / 'storage'
            ports = storage/'roms/ports'
            ports.mkdir(parents=True)
            source = storage/'games-external'
            other = storage/'games-internal'
            for card in (source, other):
                card_shortcuts(card)
                app = card/'am2arm-launcher'
                app.mkdir()
                (app/'launch.sh').write_text('printf "%s\\n" "$AM2ARM_GAME_CARD" "$AM2ARM_PORTS_DIR" "$1"')
            entry = ports/'AM2ARM.sh'
            os.link(source/'roms/ports/AM2ARM.sh', entry)
            got = subprocess.run(['sh', entry], capture_output=True, text=True)
            self.assertEqual(got.returncode, 0, got.stderr)
            self.assertEqual(got.stdout.splitlines(), [str(source), str(ports), 'auto'])
            # Matching contents alone cannot identify an unrelated card.
            entry.unlink()
            entry.write_bytes((other/'roms/ports/AM2ARM.sh').read_bytes())
            self.assertNotEqual(subprocess.run(['sh', entry], capture_output=True).returncode, 0)

    def test_builder_has_one_standalone_output(self):
        help_text = subprocess.check_output([sys.executable, SOURCE/'package_sd.py', '--help'], text=True)
        self.assertNotIn('--portmaster', help_text)
        self.assertNotIn('--screenshot', help_text)
