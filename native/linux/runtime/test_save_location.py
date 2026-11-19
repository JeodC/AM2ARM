from pathlib import Path
import tempfile
import shutil
import unittest
from launch import bind_save_directory

class SaveLocationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.native = self.root / 'home/config/game'
        self.portable = self.root / 'sd/state/config/game'

    def test_new_save_area_writes_to_card(self):
        bind_save_directory(self.native, self.portable)
        (self.native / 'save1').write_bytes(b'save')
        self.assertEqual((self.portable / 'save1').read_bytes(), b'save')
        bind_save_directory(self.native, self.portable)
        self.assertEqual((self.native / 'save1').read_bytes(), b'save')

    def test_old_state_is_copied_and_preserved(self):
        self.native.mkdir(parents=True)
        (self.native / 'save1').write_bytes(b'keep')
        backup = bind_save_directory(self.native, self.portable)
        self.assertEqual((backup / 'save1').read_bytes(), b'keep')
        self.assertEqual((self.portable / 'save1').read_bytes(), b'keep')

    def test_conflicting_save_areas_are_not_overwritten(self):
        for path, data in [(self.native, b'old'), (self.portable, b'new')]:
            path.mkdir(parents=True)
            (path / 'save1').write_bytes(data)
        with self.assertRaises(RuntimeError):
            bind_save_directory(self.native, self.portable)
        self.assertEqual((self.native / 'save1').read_bytes(), b'old')
        self.assertEqual((self.portable / 'save1').read_bytes(), b'new')

    def test_moved_card_folder_retargets_broken_link(self):
        self.native.parent.mkdir(parents=True)
        self.native.symlink_to(self.root / 'old-location/state')
        bind_save_directory(self.native, self.portable)
        self.assertEqual(self.native.resolve(), self.portable.resolve())

    def test_update_with_copied_state_keeps_both_copies(self):
        bind_save_directory(self.native, self.portable)
        (self.native / 'save1').write_bytes(b'progress')
        updated = self.root / 'new-install/state/config/game'
        shutil.copytree(self.portable, updated)
        backup = bind_save_directory(self.native, updated)
        self.assertEqual(self.native.resolve(), updated.resolve())
        self.assertEqual((backup / 'save1').read_bytes(), b'progress')
        self.assertEqual((self.portable / 'save1').read_bytes(), b'progress')
        (self.native / 'save1').write_bytes(b'new progress')
        self.assertEqual((self.portable / 'save1').read_bytes(), b'progress')

    def test_update_with_different_state_preserves_existing_link(self):
        bind_save_directory(self.native, self.portable)
        (self.native / 'save1').write_bytes(b'old')
        updated = self.root / 'new-install/state/config/game'
        shutil.copytree(self.portable, updated)
        (updated / 'save1').write_bytes(b'new')
        with self.assertRaises(RuntimeError):
            bind_save_directory(self.native, updated)
        self.assertEqual(self.native.resolve(), self.portable.resolve())
        self.assertEqual((updated / 'save1').read_bytes(), b'new')

if __name__ == '__main__':
    unittest.main()
