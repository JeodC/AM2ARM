import hashlib
import io
import json
import unittest
from zipfile import ZIP_DEFLATED, ZipFile

from make_patch_data import installation_manifest


class PatchManifestTests(unittest.TestCase):
    def manifest(self, display_version):
        memory = io.BytesIO()
        with ZipFile(memory, 'w', ZIP_DEFLATED) as archive:
            archive.writestr('edition.json', json.dumps({
                'product': 'AM2ARM', 'architecture': 'aarch64', 'edition': 'standard',
                'version': '1.6.3', 'display_version': display_version}))
            archive.writestr('data/runner', b'native game')
        with ZipFile(memory) as archive:
            return installation_manifest(archive)

    def test_manifest_records_installed_bytes_and_embedded_version(self):
        version, files = self.manifest('1.6.3')
        self.assertEqual(version, '1.6.3')
        self.assertEqual(files['data/runner'], {
            'size': 11, 'sha256': hashlib.sha256(b'native game').hexdigest()})
        self.assertIn('edition.json', files)

    def test_mismatched_display_version_stops_packaging(self):
        with self.assertRaisesRegex(ValueError, 'edition metadata'):
            self.manifest('1.6.2')
