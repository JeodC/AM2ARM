import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
from zipfile import ZipFile

from first_run import Library, find_original, single_screen
from linux_patcher import EDITIONS
from patch_core import PatchError


def game_files(edition='standard', version='1.6.3', launcher=b'launch'):
    meta = {'product': 'AM2ARM', 'edition': edition, 'architecture': 'aarch64', 'version': version}
    return {'edition.json': json.dumps(meta).encode(), 'launch.sh': launcher,
            'runtime/launch.py': b'script', 'data/runner': b'runner', 'data/game.unx': edition.encode(),
            'runtime/bin/Xwayland': b'display', 'data/options.ini': b'[Options]\n',
            'data/libAM2ARMHaptics.so': b'original rumble'}


def game_at(game, edition='standard', version='1.6.3', launcher=b'launch'):
    for name, content in game_files(edition, version, launcher).items():
        path = game/name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(content)
    return game


def write_manifests(app, version='1.6.3', dual_launcher=b'launch'):
    for key, label, launcher in [('standard', 'standard', b'launch'), ('dual', 'dual-screen', dual_launcher)]:
        files = game_files(label, version, launcher)
        integrity = {name: {'size': len(content), 'sha256': hashlib.sha256(content).hexdigest()}
                     for name, content in files.items()}
        manifest = app/'patcher/patch-bundle'/key/'assembly.json'
        manifest.parent.mkdir(parents=True, exist_ok=True)
        manifest.write_text(json.dumps({'version': version, 'installed_files': integrity}))


def donor_at(path):
    path.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(path, 'w') as archive:
        archive.writestr('AM2R 1.1/AM2R.exe', b'executable')
        archive.writestr('AM2R 1.1/data.win', b'game')
    return path


class FirstLaunchTests(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.card = Path(tmp.name)/'Game Card'
        self.ports = self.card/'roms/ports'
        self.app = self.ports/'am2arm-launcher'
        self.app.mkdir(parents=True)
        write_manifests(self.app)
        self.library = Library(self.app, self.card, self.ports)

    def test_only_standalone_display_recovery_requests_the_runtime(self):
        game = game_at(self.ports/'AM2ARM Standard', 'standard')
        with patch.dict(os.environ, {'AM2ARM_DISPLAY_NOTICE': 'westonpack'}), \
                patch('weston_graphics.prepare_graphics', create=True) as prepare:
            os.environ.pop('AM2ARM_FETCH_DISPLAY', None)
            progress = lambda *_: None
            self.assertEqual(self.library.install(None, self.library.output, 'standard', progress), (game, None))
            prepare.assert_not_called()
            os.environ['AM2ARM_FETCH_DISPLAY'] = '1'
            self.assertEqual(self.library.install(None, self.library.output, 'standard', progress), (game, None))
            prepare.assert_called_once_with(self.card, self.app/'runtime', os.environ, progress)

    def test_root_or_downloads_donor_is_found_without_moving_it(self):
        first = donor_at(self.card/'Downloads/AM2R_11.zip')
        self.assertEqual(find_original(self.app, self.card, self.ports), first)
        (self.card/'AM2ARM.zip').write_bytes(b'installer')
        second = donor_at(self.card/'AM2R_11.zip')
        self.assertIsNone(find_original(self.app, self.card, self.ports))
        first.unlink()
        self.assertEqual(find_original(self.app, self.card, self.ports), second)
        second.unlink()
        (self.card/'AM2R_11.zip').write_bytes(b'bad download')
        self.assertIsNone(find_original(self.app, self.card, self.ports))

    def test_detects_a_renamed_original_in_the_legacy_input_folder(self):
        donor = donor_at(self.app/'patcher/input/my backup.zip')
        self.assertEqual(find_original(self.app, self.card, self.ports), donor)

    def test_donor_in_preview_managed_folder_is_found_by_renamed_port(self):
        donor = donor_at(self.ports/'am2arm-launcher/AM2ARM/patcher/input/my backup.zip')
        self.assertEqual(find_original(self.ports/'am2arm/AM2ARM', self.card, self.ports), donor)

    def test_powered_sway_outputs_choose_the_edition(self):
        on = {'name': 'DSI-1', 'active': True, 'power': True}
        for extra, single in [
            ({'name': 'HDMI-1', 'active': False, 'power': True}, True),
            ({'name': 'HDMI-1', 'active': True, 'power': False}, True),
            ({'name': 'HDMI-1', 'active': True, 'dpms': False}, True),
            ({'name': 'HDMI-1', 'enabled': False}, True),
            ({'name': 'HDMI-1', 'connected': False}, True),
            ({'name': 'HDMI-1', 'current_mode': None}, True),
            ({'name': 'DSI-2', 'active': True, 'dpms': True}, False),
            ({'name': 'DSI-2', 'active': True}, False),
        ]:
            reply = subprocess.CompletedProcess([], 0, json.dumps([on, extra]))
            with self.subTest(extra=extra), patch.dict(os.environ, SWAYSOCK='test'), \
                    patch.object(Path, 'read_bytes', return_value=b'generic'), \
                    patch('subprocess.run', return_value=reply):
                self.assertEqual(single_screen('ports'), single)
        reply = subprocess.CompletedProcess([], 0, json.dumps([dict(on, active=False), dict(on, power=False)]))
        with patch.dict(os.environ, SWAYSOCK='test'), patch('subprocess.run', return_value=reply):
            with patch.object(Path, 'read_bytes', return_value=b'generic'):
                self.assertTrue(single_screen('ports'))
            with patch.object(Path, 'read_bytes', return_value=b'Anbernic RG DS'):
                self.assertFalse(single_screen('ports'))
            with patch.object(Path, 'read_bytes', return_value=b'G350'):
                self.assertTrue(single_screen('ports'))

    def test_changed_game_or_runtime_is_rejected_even_at_the_original_size(self):
        game = game_at(self.library.output/EDITIONS['standard'])
        for name in ('data/game.unx', 'data/runner', 'runtime/bin/Xwayland', 'launch.sh'):
            with self.subTest(name=name):
                self.assertEqual(self.library.selected(True), game)
                file = game/name
                original = file.read_bytes()
                file.write_bytes(b'x' * len(original))
                self.assertIsNone(self.library.selected(True))
                file.write_bytes(original)

    def test_intact_repeat_launch_uses_cached_hashes_and_a_new_manifest_invalidates_them(self):
        game = game_at(self.library.output/EDITIONS['standard'])
        self.assertEqual(self.library.selected(True), game)
        with patch('first_run.sha256_file', side_effect=AssertionError('read unchanged payload')):
            self.assertEqual(Library(self.app, self.card, self.ports).selected(True), game)
        manifest = self.app/'patcher/patch-bundle/standard/assembly.json'
        fields = json.loads(manifest.read_text())
        fields['installed_files']['data/runner']['sha256'] = '0' * 64
        manifest.write_text(json.dumps(fields))
        self.assertIsNone(Library(self.app, self.card, self.ports).selected(True))

    def test_repair_current_install_keeps_user_state_and_settings(self):
        game = game_at(self.library.output/EDITIONS['standard'])
        self.assertEqual(self.library.selected(True), game)
        (game/'data/runner').write_bytes(b'broken')
        (game/'runtime/bin/Xwayland').unlink()
        save = game/'state/config/AM2RStandardLinux/save1'
        save.parent.mkdir(parents=True)
        save.write_bytes(b'progress')
        options = game/'data/options.ini'
        options.write_bytes(b'custom settings')
        donor = donor_at(self.card/'AM2R_11.zip')
        def rebuild(source, output, edition, progress, patch_root=None):
            self.assertNotEqual(output, self.library.output)
            return game_at(output/EDITIONS[edition]), 'digest'
        with patch('first_run.prepare_game', side_effect=rebuild):
            repaired, _ = self.library.install(donor, self.library.output, 'standard', lambda *_: None)
        self.assertEqual(repaired, game)
        self.assertEqual(self.library.selected(True), game)
        self.assertEqual((game/'data/runner').read_bytes(), b'runner')
        self.assertEqual((game/'runtime/bin/Xwayland').read_bytes(), b'display')
        self.assertEqual(save.read_bytes(), b'progress')
        self.assertEqual(options.read_bytes(), b'custom settings')

    def test_bad_repair_source_preserves_existing_files_and_choice(self):
        game = game_at(self.library.output/EDITIONS['standard'])
        (game/'data/game.unx').write_bytes(b'corrupt!')
        self.library.choice.write_text('dual\n')
        donor = donor_at(self.card/'AM2R_11.zip')
        with patch('first_run.prepare_game', side_effect=PatchError('Wrong original')), self.assertRaises(PatchError):
            self.library.install(donor, self.library.output, 'standard', lambda *_: None)
        self.assertEqual((game/'data/game.unx').read_bytes(), b'corrupt!')
        self.assertEqual(self.library.choice.read_text(), 'dual\n')

    def test_user_options_created_while_rebuilding_are_preserved(self):
        game = game_at(self.library.output/EDITIONS['standard'])
        options = game/'data/options.ini'
        options.unlink()
        donor = donor_at(self.card/'AM2R_11.zip')
        def rebuild(source, output, edition, progress, patch_root=None):
            options.write_bytes(b'new settings')
            return game_at(output/EDITIONS[edition]), 'digest'
        with patch('first_run.prepare_game', side_effect=rebuild):
            self.library.install(donor, self.library.output, 'standard', lambda *_: None)
        self.assertEqual(options.read_bytes(), b'new settings')

    def test_full_setup_detects_damage_even_if_card_file_timestamps_are_unchanged(self):
        from first_run import file_stamp
        game = game_at(self.library.output/EDITIONS['standard'])
        self.assertEqual(self.library.selected(True), game)
        data = game/'data/game.unx'
        original = data.stat()
        data.write_bytes(b'corrupt!')
        def card_stamp(info):
            return file_stamp(original if info.st_ino == original.st_ino else info)
        with patch('first_run.file_stamp', side_effect=card_stamp):
            self.assertEqual(self.library.selected(True), game)
            with self.assertRaisesRegex(PatchError, 'original'):
                self.library.install(None, self.library.output, 'standard', lambda *_: None)
            self.assertIsNone(self.library.selected(True))

    def test_corrupt_selected_game_is_repaired_without_switching_to_another_save_tree(self):
        managed = game_at(self.library.output/EDITIONS['standard'])
        legacy = game_at(self.ports/EDITIONS['standard'])
        game_at(self.ports/EDITIONS['dual'], 'dual-screen')
        for game, contents in ((managed, b'new progress'), (legacy, b'old progress')):
            (game/'state').mkdir()
            (game/'state/save1').write_bytes(contents)
        self.library.choice.write_text('standard\n')
        (managed/'data/runner').write_bytes(b'broken')
        self.assertIsNone(self.library.selected(False))
        donor = donor_at(self.card/'AM2R_11.zip')
        def rebuild(source, output, edition, progress, patch_root=None):
            return game_at(output/EDITIONS[edition]), 'digest'
        with patch('first_run.prepare_game', side_effect=rebuild):
            repaired, _ = self.library.install(donor, self.library.output, 'standard', lambda *_: None)
        self.assertEqual(repaired, managed)
        self.assertEqual((managed/'state/save1').read_bytes(), b'new progress')
        self.assertEqual((legacy/'state/save1').read_bytes(), b'old progress')

    def test_invalid_rebuilt_files_cannot_replace_pending_repairs(self):
        game = game_at(self.library.output/EDITIONS['standard'])
        (game/'data/runner').write_bytes(b'broken')
        (game/'runtime/bin/Xwayland').unlink()
        donor = donor_at(self.card/'AM2R_11.zip')
        def rebuild(source, output, edition, progress, patch_root=None):
            ready = game_at(output/EDITIONS[edition])
            (ready/'data/runner').write_bytes(b'bad rr')
            return ready, 'digest'
        with patch('first_run.prepare_game', side_effect=rebuild), self.assertRaises(PatchError):
            self.library.install(donor, self.library.output, 'standard', lambda *_: None)
        self.assertEqual((game/'data/runner').read_bytes(), b'broken')
        self.assertFalse((game/'runtime/bin/Xwayland').exists())

    def test_repair_does_not_follow_a_replacement_link_into_player_files(self):
        game = game_at(self.library.output/EDITIONS['standard'])
        save = self.card/'save1'
        save.write_bytes(b'progress')
        (game/'data/runner').unlink()
        (game/'data/runner').symlink_to(save)
        donor = donor_at(self.card/'AM2R_11.zip')
        with self.assertRaisesRegex(PatchError, 'link'):
            self.library.install(donor, self.library.output, 'standard', lambda *_: None)
        self.assertTrue((game/'data/runner').is_symlink())
        self.assertEqual(save.read_bytes(), b'progress')

    def test_orphaned_sibling_launcher_is_preserved_when_reconstructing(self):
        self.library.output.mkdir(parents=True)
        entry = self.library.output/'AM2ARM Standard.sh'
        entry.write_bytes(b'player launcher')
        donor = donor_at(self.card/'AM2R_11.zip')
        def rebuild(source, output, edition, progress, patch_root=None):
            self.assertNotEqual(output, self.library.output)
            ready = game_at(output/EDITIONS[edition])
            (output/(ready.name+'.sh')).write_bytes(b'generated launcher')
            return ready, 'digest'
        with patch('first_run.prepare_game', side_effect=rebuild):
            game, _ = self.library.install(donor, self.library.output, 'standard', lambda *_: None)
        self.assertEqual(game, self.library.output/EDITIONS['standard'])
        self.assertEqual(self.library.selected(True), game)
        self.assertEqual(entry.read_bytes(), b'player launcher')

    def test_supported_device_haptics_and_editable_options_survive_verification(self):
        game = game_at(self.library.output/EDITIONS['standard'])
        rumble = self.app/'runtime/rumble/library.json'
        rumble.parent.mkdir(parents=True)
        rumble.write_text(json.dumps({'brick': hashlib.sha256(b'brick device rumble').hexdigest(),
                                     'original': hashlib.sha256(b'original rumble').hexdigest()}))
        (game/'data/libAM2ARMHaptics.so').write_bytes(b'brick device rumble')
        (game/'data/options.ini').write_text('my settings')
        self.assertEqual(Library(self.app, self.card, self.ports).selected(True), game)

    def test_legacy_game_with_saves_is_played_without_repatching(self):
        game = game_at(self.ports/'AM2ARM Standard')
        save = game/'state/config/AM2RStandardLinux/save1'
        save.parent.mkdir(parents=True)
        save.write_bytes(b'existing progress')
        self.assertEqual(self.library.selected(single=True), game)
        self.assertEqual(save.read_bytes(), b'existing progress')
        (game/'data/runner').unlink()
        self.assertIsNone(self.library.selected(single=True))

    def test_legacy_direct_install_can_have_a_custom_game_folder(self):
        game = game_at(self.card/'My Games/AM2ARM Standard')
        record = self.card/'AM2ARM/state/installation.json'
        record.parent.mkdir(parents=True)
        record.write_text(json.dumps({'game':'My Games/AM2ARM Standard'}))
        self.assertEqual(self.library.selected(single=True), game)
        record.write_text(json.dumps({'game':'../escape'}))
        self.assertIsNone(self.library.selected(single=True))

    def test_dual_choice_is_remembered_without_the_original(self):
        first = game_at(self.ports/'AM2ARM Standard')
        second = game_at(self.ports/'AM2ARM Dual Screen', 'dual-screen')
        self.assertIsNone(self.library.selected(single=False))
        game, _ = self.library.install(None, self.library.output, 'dual', lambda *_: None)
        self.assertEqual(game, second)
        self.assertEqual(self.library.selected(single=False), second)
        self.assertEqual(self.library.selected(single=True), first)
        self.assertFalse(self.library.output.is_relative_to(self.app))

    def test_an_older_game_is_preserved_and_does_not_mask_a_new_install(self):
        old = game_at(self.ports/'AM2ARM Standard',version='1.6.1')
        (old/'save1').write_text('progress')
        self.assertIsNone(self.library.selected(True))
        current = game_at(self.library.output/'AM2ARM Standard')
        self.assertEqual(self.library.selected(True),current)
        self.assertEqual((old/'save1').read_text(),'progress')

    def test_failed_install_does_not_select_a_game(self):
        from patch_core import PatchError
        with self.assertRaises(PatchError):
            self.library.install(self.card/'missing.zip', self.library.output, 'standard', lambda *_: None)
        self.assertIsNone(self.library.selected(single=True))


if __name__ == '__main__':
    unittest.main()
