from pathlib import Path
import os
import stat
import subprocess
import tempfile
import unittest
from unittest.mock import patch

from compat_display import identify, video_drivers
import nextui_session
from nextui_controls import evdev_mapping
from nextui_session import RUNTIME, command
from route import resolve_display
from trimui_device import display_size


FIRMWARE = 'NAME="AmberELEC"\nID="coreelec"\n'


class AmberELECAudio(unittest.TestCase):
    def test_keeps_a_working_firmware_sink(self):
        env = {'PULSE_SERVER': 'unix:/firmware/native', 'PULSE_COOKIE': '/firmware/cookie'}
        original = env.copy()
        with tempfile.TemporaryDirectory() as folder, patch('nextui_session.subprocess.run',
                return_value=subprocess.CompletedProcess([], 0, 'alsa_output.speaker\n')), \
                patch('nextui_session.start') as start:
            root = Path(folder)
            nextui_session.prepare_amber_audio(env, root, root/'audio.log')
            start.assert_not_called()
            self.assertEqual(list(root.iterdir()), [])
        self.assertEqual(env, original)

    def test_stopped_or_silent_firmware_server_uses_private_alsa(self):
        for status, sink in ((1, ''), (0, 'auto_null\n')):
            with self.subTest(sink=sink), tempfile.TemporaryDirectory() as folder:
                root = Path(folder)
                env = {'HOME': '/portable/saves', 'PULSE_SERVER': 'unix:/firmware/native'}
                with patch('nextui_session.subprocess.run', return_value=subprocess.CompletedProcess([], status, sink)), \
                        patch('nextui_session.start') as start, patch('nextui_session.wait_ready'):
                    nextui_session.prepare_amber_audio(env, root, root/'audio.log')
                self.assertEqual(env['HOME'], '/portable/saves')
                self.assertEqual(env['PULSE_SERVER'], 'unix:' + str(root/'audio'))
                self.assertEqual(env['PULSE_SINK'], 'am2arm')
                cookie = Path(env['PULSE_COOKIE'])
                self.assertEqual(cookie.stat().st_size, 256)
                self.assertEqual(stat.S_IMODE(cookie.stat().st_mode), 0o600)
                self.assertEqual(cookie.parent, root)
                args, audio_env, logfile = start.call_args.args
                self.assertTrue(any(arg.startswith('module-alsa-sink ') and 'device=default' in arg for arg in args))
                self.assertEqual(audio_env['PULSE_SERVER'], env['PULSE_SERVER'])
                self.assertEqual(logfile, root/'audio.log')


class AmberELECDisplay(unittest.TestCase):
    def test_display_processes_use_a_matched_loader_and_libc(self):
        for profile in ('g350', 'rg351p', 'smartpros', 'flip', 'brick'):
            environment = {'AM2ARM_DEVICE_PROFILE': profile, 'LD_LIBRARY_PATH': str(RUNTIME / 'core')}
            with self.subTest(profile=profile), patch.dict(os.environ, environment):
                args = command('/game/runner', ['-game', '/game/game.unx'], extra=('/game/lib', '/usr/lib'))
                directories = args[2].split(':')
                self.assertEqual(args[-3:], ['/game/runner', '-game', '/game/game.unx'])
                self.assertIn('/game/lib', directories)
                if profile in ('g350', 'rg351p'):
                    self.assertEqual(args[0], '/usr/lib/ld-linux-aarch64.so.1')
                    self.assertNotIn(str(RUNTIME / 'core'), directories)
                    self.assertLess(directories.index('/game/lib'), directories.index('/usr/lib'))
                    self.assertLess(directories.index('/usr/lib'), directories.index(str(RUNTIME / 'lib')))
                else:
                    self.assertEqual(args[0], str(RUNTIME / 'core/ld-linux-aarch64.so.1'))
                    self.assertEqual(directories[0], str(RUNTIME / 'core'))

    def test_firmware_models_select_the_native_panel_without_a_compositor(self):
        def no_wayland(env):
            raise RuntimeError('No compositor')

        for model, profile, size in (
            ('Anbernic RG35', 'g350', (640, 480)),
            ('BatleXP G350', 'g350', (640, 480)),
            ('Anbernic RG351P', 'rg351p', (480, 320)),
        ):
            with self.subTest(model=model):
                board = lambda: identify(model, '', '', FIRMWARE)
                route, selected = resolve_display('ports', {}, session=no_wayland, device=board)
                self.assertEqual((route, selected['AM2ARM_DEVICE_PROFILE']), ('direct', profile))
                self.assertEqual(display_size(profile), size)
                self.assertEqual(video_drivers(profile, ['dummy', 'KMSDRM', 'offscreen']), ['KMSDRM'])
                self.assertEqual(video_drivers(profile, ['dummy', 'x11', 'offscreen', 'evdev']), [])
                self.assertEqual(resolve_display('ports', {}, session=lambda env: env, device=board)[0], 'ports')

    def test_soc_or_firmware_alone_does_not_select_a_display(self):
        for model, firmware in [('other RK3326', FIRMWARE),
                                ('Anbernic RG351P', 'NAME="CoreELEC"\nID="coreelec"\n'),
                                ('Anbernic RG35', 'NAME="ROCKNIX"\n')]:
            with self.subTest(model=model, firmware=firmware), self.assertRaises(RuntimeError):
                identify(model, 'Rockchip RK3326', '', firmware)

    def test_game_receives_its_firmware_controller_mapping(self):
        with tempfile.TemporaryDirectory() as folder:
            database = Path(folder) / 'gamecontrollerdb.txt'
            g350 = '190000004b4800000011000000010000,GO-Super Gamepad,a:b1,platform:Linux,'
            rg351p = '03000000091200000031000011010000,OpenSimHardware OSH PB Controller,a:b0,platform:Linux,'
            database.write_text('# Firmware mappings\n' + g350 + '\n' + rg351p + '\n')
            self.assertEqual(evdev_mapping('g350', database=database), g350)
            self.assertEqual(evdev_mapping('rg351p', database=database), rg351p)
            self.assertEqual(evdev_mapping('rg351p', database=Path(folder) / 'missing'), '')
