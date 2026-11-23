import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from test_first_run import game_at, write_manifests

SOURCE = Path(__file__).resolve().parents[1]


class PortsSession(unittest.TestCase):
    """Run the shipped shell logic with only the firmware and display processes substituted."""

    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.card = Path(temp.name)/'Two Screen'
        self.ports = self.card/'menu'
        self.app = self.card/'am2arm-launcher/AM2ARM'
        self.rt = self.app/'runtime'
        (self.rt/'core').mkdir(parents=True)
        from first_run import __file__ as first_run
        import linux_patcher
        patcher = Path(linux_patcher.__file__).parent
        (self.app/'patcher').mkdir()
        for filename in ('linux_patcher.py','patch_core.py','handheld_platform.py'):
            (self.app/'patcher'/filename).symlink_to(patcher/filename)
        for filename in ('first_run.py','nextui_layout.py','menu_entries.py','start.sh','session.sh'):
            shutil.copy(Path(first_run).parent/filename,self.rt)
        shutil.copy(SOURCE/'launch.sh',self.app)
        write_manifests(self.app)
        self.bin = self.card/'bin'
        self.bin.mkdir()
        self.program(self.bin/'uname','echo aarch64')
        self.program(self.bin/'swaymsg',"""echo '[{"name":"top"},{"name":"bottom"}]'""")
        self.program(self.rt/'core/ld-linux-aarch64.so.1','shift 3\nunset PYTHONHOME\nexec python3 -B "$@"')
        self.simulate_backend('ports')
        self.env = dict(os.environ,PATH=str(self.bin)+':'+os.environ['PATH'],
            AM2ARM_GAME_CARD=str(self.card),AM2ARM_FRONTEND='ports',AM2ARM_PORTS_DIR=str(self.ports),
            SWAYSOCK='display', TRACE=str(self.card/'actions'))
        self.setup = self.app/'patcher/launch.sh'
        self.game = self.ports/'AM2ARM Dual Screen'

    def simulate_backend(self, backend):
        (self.rt/'route.py').write_text(
            'import os, sys\n'
            f'os.environ["AM2ARM_DISPLAY_PATH"] = {backend!r}\n'
            'os.execv(sys.argv[2], sys.argv[2:])\n')

    def program(self, path, commands):
        path.write_text('#!/bin/sh\n'+commands+'\n')
        path.chmod(0o755)

    def launch(self, *args):
        return subprocess.run(['sh',self.app/'launch.sh','auto',*args],env=self.env,capture_output=True,text=True)

    def test_a_completed_dual_game_opens_directly_with_system_python(self):
        game_at(self.game,'dual-screen')
        self.program(self.game/'launch.sh','test -z "${PYTHONHOME:-}${PYTHONPATH:-}" && echo play >> "$TRACE"')
        write_manifests(self.app, dual_launcher=(self.game/'launch.sh').read_bytes())
        self.program(self.setup,'exit 36')
        self.assertEqual(self.launch().returncode,0)
        self.assertEqual((self.card/'actions').read_text(),'play\n')

    def test_canceling_explicit_setup_does_not_start_a_previous_game(self):
        game_at(self.game,'dual-screen')
        self.program(self.setup,'echo setup >> "$TRACE"\nexit 2')
        self.program(self.game/'launch.sh','echo play >> "$TRACE"')
        write_manifests(self.app, dual_launcher=(self.game/'launch.sh').read_bytes())
        self.assertEqual(self.launch('--setup').returncode,2)
        self.assertEqual((self.card/'actions').read_text(),'setup\n')

    def test_first_install_hands_off_once_and_repeat_launch_skips_the_installer(self):
        prepared = game_at(self.card/'fixture','dual-screen')
        self.program(prepared/'launch.sh','echo play >> "$TRACE"')
        write_manifests(self.app, dual_launcher=(prepared/'launch.sh').read_bytes())
        self.ports.mkdir()
        self.program(self.setup,'''echo setup >> "$TRACE"
mv "$AM2ARM_GAME_CARD/fixture" "$AM2ARM_PORTS_DIR/AM2ARM Dual Screen"''')
        self.assertEqual(self.launch().returncode,0)
        self.assertEqual(self.launch().returncode,0)
        self.assertEqual((self.card/'actions').read_text().splitlines(),['setup','play','play'])

    def test_real_router_passes_the_same_endpoint_to_setup_and_play(self):
        from test_standalone_routes import WaylandServer
        for name in ('route.py', 'compat_display.py', 'trimui_device.py'):
            shutil.copy(SOURCE/'runtime'/name, self.rt/name)
        display_dir = self.card/'display sockets'
        display_dir.mkdir()
        self.env.update(XDG_RUNTIME_DIR=str(display_dir))
        self.env.pop('WAYLAND_DISPLAY', None)
        prepared = game_at(self.card/'fixture','dual-screen')
        self.program(prepared/'launch.sh', 'echo "game $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" >> "$TRACE"')
        write_manifests(self.app, dual_launcher=(prepared/'launch.sh').read_bytes())
        self.ports.mkdir()
        self.program(self.setup, '''echo "setup $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" >> "$TRACE"
mv "$AM2ARM_GAME_CARD/fixture" "$AM2ARM_PORTS_DIR/AM2ARM Dual Screen"''')
        endpoint = display_dir/'wayland-3'
        with WaylandServer(endpoint):
            result = self.launch()
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.card/'actions').read_text().splitlines(), [f'setup {endpoint}', f'game {endpoint}'])

    def direct_audio_session(self, profile, **overrides):
        self.simulate_backend('direct')
        game_at(self.ports/'AM2ARM Standard', 'standard')
        firmware_home = self.card/'firmware home'
        config = firmware_home/'custom config'
        cookie = config/'pulse/cookie'
        cookie.parent.mkdir(parents=True, exist_ok=True)
        cookie.touch()
        for key in ('PULSE_SERVER', 'PULSE_COOKIE'):
            self.env.pop(key, None)
        self.env.update(HOME=str(firmware_home), XDG_CONFIG_HOME=str(config),
                        AM2ARM_DEVICE_PROFILE=profile, **overrides)
        self.program(self.bin/'pactl', r'''[ "$1" = info ] || exit 1
printf '%s\n' "$HOME" "$XDG_CONFIG_HOME" >> "$TRACE.probe"
echo 'Server String: /run/firmware/pulse/native'
''')
        (self.rt/'nextui_session.py').write_text(
            'import json, os\nfrom pathlib import Path\n'
            'keys = ("HOME", "XDG_CONFIG_HOME", "PULSE_SERVER", "PULSE_COOKIE")\n'
            'Path(os.environ["TRACE"]).write_text(json.dumps([os.getenv(k) for k in keys]))\n'
            'raise SystemExit(int(os.getenv("GAME_STATUS", "0")))\n')
        result = self.launch()
        self.assertEqual(result.returncode, int(overrides.get('GAME_STATUS', 0)), result.stderr)
        return json.loads((self.card/'actions').read_text())

    def test_amber_preserves_authenticated_audio_before_moving_save_home(self):
        home, config, server, cookie = self.direct_audio_session('g350', GAME_STATUS='42')
        firmware = self.card/'firmware home'
        self.assertEqual(home, str(self.card/'AM2ARM-data/home'))
        self.assertEqual(config, str(Path(home)/'.config'))
        self.assertEqual(server, '/run/firmware/pulse/native')
        self.assertEqual(cookie, str(firmware/'custom config/pulse/cookie'))
        self.assertEqual((self.card/'actions.probe').read_text().splitlines(),
                         [str(firmware), str(firmware/'custom config')])

    def test_amber_keeps_an_explicit_audio_session(self):
        _, _, server, cookie = self.direct_audio_session(
            'rg351p', PULSE_SERVER='unix:/other/native', PULSE_COOKIE='/other/auth')
        self.assertEqual((server, cookie), ('unix:/other/native', '/other/auth'))
        self.assertFalse((self.card/'actions.probe').exists())

    def test_other_direct_devices_keep_their_audio_environment(self):
        _, _, server, cookie = self.direct_audio_session('brick')
        self.assertEqual((server, cookie), (None, None))
        self.assertFalse((self.card/'actions.probe').exists())

    def test_standalone_retries_an_installed_game_once_after_display_setup(self):
        game_at(self.ports/'AM2ARM Standard', 'standard')
        self.simulate_backend('direct')
        (self.rt/'nextui_session.py').write_text(
            "import os, sys\nfrom pathlib import Path\n"
            "trace = Path(os.environ['TRACE'])\nmode = sys.argv[1]\n"
            "with trace.open('a') as out: print(mode, file=out)\n"
            "if mode == 'game': raise SystemExit(78)\n"
            "assert os.environ['AM2ARM_DISPLAY_NOTICE'] == 'westonpack'\n"
            "raise SystemExit(int(os.environ.get('SETUP_EXIT', '0')))\n")
        self.env['AM2ARM_FETCH_DISPLAY'] = '1'
        trace = self.card/'actions'
        self.assertEqual(self.launch().returncode, 78)
        self.assertEqual(trace.read_text().splitlines(), ['game', 'patcher', 'game'])
        trace.unlink()
        self.env['SETUP_EXIT'] = '2'
        self.assertEqual(self.launch().returncode, 2)
        self.assertEqual(trace.read_text().splitlines(), ['game', 'patcher'])
