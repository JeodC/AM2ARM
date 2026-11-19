"""Exact patcher manifests restore UI inputs without broad payload support."""
import copy
import hashlib
import json
from pathlib import Path
import shutil
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from test_restore import RestoreTests
import restore_project as tool


class PatcherProjectTests(RestoreTests):
    def setUp(self):
        super().setUp()
        self.entrypoint = 'linux_patcher.py'
        (self.project / 'AM2R-project.yyp').rename(self.project / self.entrypoint)
        self.manifest['source_files'][0]['path'] = self.entrypoint
        self.manifest.update(project_file=self.entrypoint, project_kind='autopatcher',
                             platform='linux', edition='autopatcher')
        self.save_manifest()

    def test_patcher_assets_use_catalog_selected_subbundle(self):
        self.manifest['bundle_path'] = 'patcher-assets'
        self.save_manifest()
        manifest_hash = tool.digest_file(self.project / 'asset-inputs.json')
        sub = self.bundle / 'patcher-assets'
        sub.mkdir()
        for name in ['manifest.json', 'assets.xdelta']:
            (self.bundle / name).rename(sub / name)
        description = dict(self.manifest, manifest_sha256=manifest_hash)
        raw = json.dumps(description).encode()
        (self.bundle / 'patcher.json').write_bytes(raw)
        catalog = {'schema': 1, 'bundle_sha256': '1' * 64,
                   'asset_bundles': {'patcher-assets': self.manifest['bundle_sha256']},
                   'projects': {manifest_hash: [{'path': 'patcher.json', 'size': len(raw),
                                              'sha256': hashlib.sha256(raw).hexdigest()}]}}
        (self.bundle / 'catalog.json').write_text(json.dumps(catalog))
        result = self.restore()
        self.assertEqual(result['restored'], 3)
        self.assertEqual(tool.inspect_project(self.project, self.bundle)['missing_assets'], [])
        # A changed public fingerprint cannot select the catalog entry.
        (self.project / 'asset-inputs.json').write_text(json.dumps(dict(self.manifest, snapshot='foreign')))
        with self.assertRaises(tool.RestoreError):
            self.restore()

    def test_only_known_patcher_entrypoints_are_accepted(self):
        for project_kind, platform, entrypoint in [('other', 'linux', self.entrypoint),
                ('autopatcher', 'other', self.entrypoint),
                ('autopatcher', 'android', self.entrypoint)]:
            with self.subTest(kind=project_kind, platform=platform, entrypoint=entrypoint):
                self.manifest.update(project_kind=project_kind, platform=platform, project_file=entrypoint)
                self.save_manifest()
                with self.assertRaises(tool.RestoreError):
                    self.restore()
                self.assertFalse((self.project / 'sprites').exists())

    def test_android_patcher_assets_restore_without_code_changes(self):
        target = 'am2r_android_patcher.py'
        (self.project / self.entrypoint).rename(self.project / target)
        self.manifest['source_files'][0]['path'] = target
        self.manifest.update(platform='android', project_file=target)
        self.save_manifest()
        before = (self.project / target).read_bytes()
        self.assertEqual(self.restore()['restored'], 3)
        self.assertEqual((self.project / target).read_bytes(), before)


if __name__ == '__main__':
    unittest.main()
