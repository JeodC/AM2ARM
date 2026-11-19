import ctypes
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


HERE = Path(__file__).resolve().parent


class TransferTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.available = (HERE / 'save_transfer.cpp').is_file()
        if not cls.available:
            return
        subprocess.run(['g++', '-std=c++17', '-Wall', '-Wextra', '-Werror',
                        '-fPIC', '-shared', str(HERE / 'save_transfer.cpp'),
                        '-o', str(HERE / 'test-transfer.so')], check=True)
        cls.lib = ctypes.CDLL(str(HERE / 'test-transfer.so'))
        for name in ('Init', 'List', 'Export', 'Import'):
            fun = getattr(cls.lib, 'AM2ARM_Save' + name)
            fun.argtypes = [ctypes.c_char_p]
            fun.restype = ctypes.c_double if name == 'Init' else ctypes.c_char_p
        cls.lib.AM2ARM_SaveApply.argtypes = [ctypes.c_char_p, ctypes.c_char_p]
        cls.lib.AM2ARM_SaveApply.restype = ctypes.c_double

    def setUp(self):
        self.assertTrue(self.available, 'Linux save-transfer backend is not implemented')
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.saves = self.base / 'saves'
        self.card = self.base / 'card'
        self.saves.mkdir()
        self.card.mkdir()
        self.assertEqual(self.lib.AM2ARM_SaveInit(os.fsencode(self.saves)), 1)

    def call(self, name, path):
        return json.loads(getattr(self.lib, 'AM2ARM_Save' + name)(os.fsencode(path)))

    def test_list_sorts_folders_and_preserves_paths_with_unicode(self):
        for name in ('Zulu', 'étoile', 'alpha', '.hidden'):
            (self.card / name).mkdir()
        (self.card / 'save1').write_bytes(b'progress')
        result = self.call('List', self.card)
        self.assertTrue(result['ok'])
        self.assertEqual([d['name'] for d in result['dirs']], ['alpha', 'Zulu', 'étoile'])
        self.assertEqual(result['parent'], str(self.base))

    def test_export_creates_distinct_complete_backups_without_touching_live(self):
        (self.saves / 'save1').write_bytes(b'live native save')
        (self.saves / 'backupstage_save1').write_bytes(b'converted PC save')
        (self.saves / 'backupstage_config.ini').write_bytes(b'not progress')
        first = self.call('Export', self.card)
        second = self.call('Export', self.card)
        self.assertTrue(first['ok'])
        self.assertTrue(second['ok'])
        self.assertNotEqual(first['path'], second['path'])
        self.assertEqual((Path(first['path']) / 'save1').read_bytes(), b'converted PC save')
        self.assertEqual([p.name for p in Path(first['path']).iterdir()], ['save1'])
        self.assertEqual((self.saves / 'save1').read_bytes(), b'live native save')

    def test_empty_export_does_not_claim_success(self):
        self.assertFalse(self.call('Export', self.card)['ok'])
        self.assertEqual(list(self.card.iterdir()), [])

    def test_failed_export_does_not_leave_a_partial_visible_backup(self):
        (self.saves / 'backupstage_save1').write_bytes(b'valid stage')
        (self.saves / 'backupstage_save2').write_bytes(b'x' * (1048576 + 1))
        self.assertFalse(self.call('Export', self.card)['ok'])
        self.assertEqual(list(self.card.iterdir()), [])

    def test_import_only_stages_allowlisted_files_and_drops_stale_stages(self):
        (self.saves / 'save1').write_bytes(b'live')
        (self.saves / 'restorestage_save2').write_bytes(b'stale')
        (self.card / 'save1').write_bytes(b'import')
        (self.card / 'config.ini').write_bytes(b'untrusted config')
        result = self.call('Import', self.card)
        self.assertTrue(result['ok'])
        self.assertEqual(result['files'], 1)
        self.assertEqual((self.saves / 'restorestage_save1').read_bytes(), b'import')
        self.assertFalse((self.saves / 'restorestage_save2').exists())
        self.assertFalse((self.saves / 'config.ini').exists())
        self.assertEqual((self.saves / 'save1').read_bytes(), b'live')

    def test_import_rejects_symlinks_and_clears_partial_staging(self):
        (self.card / 'save1').write_bytes(b'incoming')
        (self.card / 'save2').symlink_to(self.card / 'save1')
        self.assertFalse(self.call('Import', self.card)['ok'])
        self.assertEqual(list(self.saves.glob('restorestage_*')), [])

    def test_import_rejects_empty_or_oversized_files(self):
        for content in (b'', b'x' * (1048576 + 1)):
            (self.card / 'save1').write_bytes(content)
            self.assertFalse(self.call('Import', self.card)['ok'])
        self.assertEqual(list(self.saves.iterdir()), [])

    def test_apply_keeps_original_snapshot_and_only_overwrites_chosen_slot(self):
        (self.saves / 'save1').write_bytes(b'slot one')
        (self.saves / 'save2').write_bytes(b'slot two')
        (self.saves / 'restorestage_save1').write_bytes(b'validated incoming')
        self.assertEqual(self.lib.AM2ARM_SaveApply(b'save1', b'save2'), 1)
        self.assertEqual((self.saves / 'save1').read_bytes(), b'slot one')
        self.assertEqual((self.saves / 'save2').read_bytes(), b'validated incoming')
        snapshots = list((self.saves / 'pre-restore-backup').glob('*/save2'))
        self.assertEqual(len(snapshots), 1)
        self.assertEqual(snapshots[0].read_bytes(), b'slot two')

    def test_invalid_pairs_and_missing_stage_leave_live_data_alone(self):
        (self.saves / 'save1').write_bytes(b'original')
        for source, target in ((b'../save1', b'save1'), (b'data.sav', b'save1'),
                               (b'save1', b'extras.sav'), (b'save2', b'save1')):
            self.assertEqual(self.lib.AM2ARM_SaveApply(source, target), 0)
        self.assertEqual((self.saves / 'save1').read_bytes(), b'original')

    def test_unlock_records_apply_together(self):
        for name in ('data.sav', 'extras.sav'):
            (self.saves / name).write_bytes(b'previous ' + name.encode())
            (self.saves / ('restorestage_' + name)).write_bytes(b'new ' + name.encode())
        self.assertEqual(self.lib.AM2ARM_SaveApply(b'data.sav', b'data.sav'), 1)
        for name in ('data.sav', 'extras.sav'):
            self.assertEqual((self.saves / name).read_bytes(), b'new ' + name.encode())

    def test_interrupted_unlock_commit_recovers_both_records_before_loading(self):
        journal = self.saves / 'restore-transaction-linux'
        (journal / 'old').mkdir(parents=True)
        (journal / 'new').mkdir()
        (journal / 'targets').write_text('data.sav\nextras.sav\n')
        (journal / 'READY').write_bytes(b'1')
        (journal / 'old/data.sav').write_bytes(b'previous records')
        (self.saves / 'data.sav').write_bytes(b'partial new records')
        (self.saves / 'extras.sav').write_bytes(b'newly created extras')
        self.assertEqual(self.lib.AM2ARM_SaveInit(os.fsencode(self.saves)), 1)
        self.assertEqual((self.saves / 'data.sav').read_bytes(), b'previous records')
        self.assertFalse((self.saves / 'extras.sav').exists())
        self.assertFalse(journal.exists())

    def test_finished_commit_is_retained_on_restart(self):
        journal = self.saves / 'restore-transaction-linux'
        (journal / 'old').mkdir(parents=True)
        (journal / 'new').mkdir()
        (journal / 'targets').write_text('save1\n')
        (journal / 'READY').write_bytes(b'1')
        (journal / 'FINISHED').write_bytes(b'1')
        (journal / 'old/save1').write_bytes(b'old')
        (self.saves / 'save1').write_bytes(b'new')
        self.assertEqual(self.lib.AM2ARM_SaveInit(os.fsencode(self.saves)), 1)
        self.assertEqual((self.saves / 'save1').read_bytes(), b'new')

    def test_malformed_recovery_journal_is_retained_for_repair(self):
        journal = self.saves / 'restore-transaction-linux'
        journal.mkdir()
        (journal / 'targets').write_text('../outside\n')
        (journal / 'READY').write_bytes(b'1')
        (self.base / 'outside').write_bytes(b'keep')
        self.assertEqual(self.lib.AM2ARM_SaveInit(os.fsencode(self.saves)), 0)
        self.assertEqual((self.base / 'outside').read_bytes(), b'keep')
        self.assertTrue(journal.exists())

    def test_live_symlinks_cannot_redirect_writes(self):
        outside = self.base / 'outside'
        outside.write_bytes(b'keep')
        (self.saves / 'save1').symlink_to(outside)
        (self.saves / 'restorestage_save1').write_bytes(b'new')
        self.assertEqual(self.lib.AM2ARM_SaveApply(b'save1', b'save1'), 0)
        self.assertEqual(outside.read_bytes(), b'keep')


if __name__ == '__main__':
    unittest.main()
