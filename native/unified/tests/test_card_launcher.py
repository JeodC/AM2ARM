import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
from zipfile import ZipFile

SOURCE = Path(__file__).resolve().parents[1]
sys.path.insert(0,str(SOURCE))
sys.path.insert(0,str(SOURCE/'menus'))
import package_sd
from launch_layout import card_shortcuts


class MenuEntrypoints(unittest.TestCase):
    def test_keyboard_compiler_uses_runtime_supplied_by_display_launcher(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            runtime = root / 'game card' / 'runtime'
            (runtime / 'core').mkdir(parents=True)
            loader = runtime / 'core/ld-linux-aarch64.so.1'
            loader.write_text('#!/bin/sh\nprintf "%s\\n" "$@"\n')
            loader.chmod(0o755)
            server = root / 'display-server'
            server.mkdir()
            compiler = server / 'xkbcomp'
            compiler.write_bytes((SOURCE / 'runtime/bin/xkbcomp').read_bytes())
            env = dict(os.environ, AM2ARM_RUNTIME_DIR=str(runtime), AM2ARM_DISPLAY_PATH='direct')
            result = subprocess.run(['sh', './xkbcomp', '-xkm', 'a keymap'], cwd=server,
                                    env=env, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout.splitlines(), [
                '--library-path', f'{runtime}/core:{runtime}/lib', str(runtime / 'bin/xkbcomp.bin'),
                '-xkm', 'a keymap',
            ])

    def test_every_card_shortcut_runs_one_game_from_a_card_with_spaces(self):
        with tempfile.TemporaryDirectory() as folder:
            card = Path(folder)/'My Games'
            app = card/'am2arm-launcher'
            app.mkdir(parents=True)
            (app/'launch.sh').write_text('printf "%s\\n" "$AM2ARM_FRONTEND" "$AM2ARM_GAME_CARD" "$1" "${2:-play}"\n')
            entries = card_shortcuts(card)
            for name, frontend in {'Tools/tg5040/AM2ARM.pak/launch.sh':'nextui','Tools/my355/AM2ARM.pak/launch.sh':'tools',
                'Apps/AM2ARM/launch.sh':'stock','App/AM2ARM/launch.sh':'spruce','ports/AM2ARM.sh':'ports',
                'roms/ports/AM2ARM.sh':'ports','ports/AM2ARM Editions.sh':'ports'}.items():
                with self.subTest(name=name):
                    result=subprocess.check_output(['sh',entries[name]],text=True,env=dict(os.environ,SDCARD_PATH='/wrong'))
                    self.assertEqual(result.splitlines(),[frontend,str(card),'auto','--setup' if 'Editions' in name else 'play'])
            for folder in ('App','Apps'):
                config=json.loads((card/folder/'AM2ARM/config.json').read_text())
                self.assertEqual(config['label'],'AM2ARM')
                self.assertEqual((card/folder/'AM2ARM'/config['icon']).resolve(), app/'AM2ARM/patcher/assets/app-icon.png')
            self.assertEqual(len(entries),len({name.casefold() for name in entries}))

    def test_unpacker_that_discards_modes_can_still_start_the_runtime(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);app=root/'AM2ARM';app.mkdir()
            tool=app/'native tool'
            tool.write_text('#!/bin/sh\necho "game ready"\n')
            tool.chmod(0o644)
            (root/'executables.txt').write_text('AM2ARM/native tool\n')
            (app/'launch.sh').write_text('exec "$(dirname "$0")/native tool"\n')
            entry=root/'launch.sh'
            entry.write_bytes((SOURCE/'menus/payload.sh').read_bytes())
            run=subprocess.run(['sh',entry],text=True,capture_output=True)
            self.assertEqual(run.returncode,0,run.stderr)
            self.assertEqual(run.stdout.strip(),'game ready')
            self.assertTrue(os.access(tool,os.X_OK))


class PackageTests(unittest.TestCase):
    def test_card_output_uses_the_requested_bundle_and_current_patcher(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            project, base, bundle = root/'project', root/'previous', root/'new patches'
            patcher = base/'patcher'
            scripts = root/'scripts'
            def put(path, data):
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(data)
                return path
            for name in ('runtime/profile.py', 'launch.sh', 'menus/payload.sh', 'README-card.txt',
                         'menus/README-licenses.txt', 'menus/dependencies/README.md',
                         'menus/dependencies/inventory.tsv'):
                put(project/name, b'source')
            for name in ('bin/Xwayland', 'bin/Xvfb', 'kms/libGL.so.1', 'graphics/libcrusty.so', 'graphics/libGL.so.1'):
                put(base/'runtime'/name, b'component')
            for name in ('libGL.so.1', 'libcrusty.so'):
                put(patcher/'runtime/graphics'/name, b'older component')
            for name in ('assets/app-icon.png', 'vendor/xdelta3/linux-arm64/xdelta3',
                         'vendor/xdelta3/linux-arm64/xdelta3.bin', 'handheld_gui.py', 'linux_patcher.py'):
                put(patcher/name, b'previous')
            for name in ('handheld_gui.py', 'linux_patcher.py', 'handheld-launch.sh', 'compatibility-check.sh'):
                put(scripts/name, b'current')
            for edition in ('standard', 'dual'):
                put(bundle/edition/'assembly.json', b'{"version":"1.6.3"}')
                for name in ('wrapper.bin', 'game_data.xdelta'):
                    put(bundle/edition/name, b'new edition')

            card = root/'card.zip'
            cli = ['package_sd.py', str(patcher), str(base), str(card), '--patcher-source', str(scripts),
                   '--patch-bundle', str(bundle), '--version', '1.6.3']

            with patch.object(package_sd, 'SOURCE', project), patch.object(sys, 'argv', cli):
                package_sd.main()
            with ZipFile(card) as archive:
                self.assertIn('am2arm-launcher/dependencies/inventory.tsv', archive.namelist())
                self.assertIn('am2arm-launcher/licenses/README.txt', archive.namelist())
                self.assertEqual(archive.read('am2arm-launcher/AM2ARM/patcher/linux_patcher.py'), b'current')
                self.assertEqual(archive.read('am2arm-launcher/AM2ARM/patcher/patch-bundle/dual/wrapper.bin'),
                                 b'new edition')
                self.assertNotIn('am2arm/launch.sh', archive.namelist())
                self.assertIn('am2arm-launcher/AM2ARM/runtime/kms/libGL.so.1', archive.namelist())
                self.assertNotIn('am2arm-launcher/AM2ARM/runtime/graphics/libGL.so.1', archive.namelist())
                self.assertNotIn('am2arm-launcher/AM2ARM/runtime/graphics/libcrusty.so', archive.namelist())
            put(bundle/'dual/assembly.json', b'{"version":"1.6.2"}')
            with self.assertRaisesRegex(ValueError, 'Edition versions'):
                package_sd.collect(patcher, base, scripts, bundle, '1.6.3')
            put(patcher/'input/my original.zip', b'private input')
            with self.assertRaisesRegex(ValueError, 'Unexpected input'):
                package_sd.collect(patcher, base, scripts, bundle)
