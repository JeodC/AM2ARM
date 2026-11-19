"""Rebuilding a catalog must relocate assets into its new shared bundle."""
import copy
import json
from pathlib import Path
import unittest
from unittest import mock
import zipfile
import build_catalog as builder
import restore_project as tool
import test_restore as fixtures


class CatalogRebuildTests(unittest.TestCase):
    def test_rebuild_mixed_game_and_patcher_catalog(self):
        fixture = fixtures.RestoreTests()
        fixture.setUp()
        self.addCleanup(fixture.doCleanups)
        releases = []
        projects = []
        for kind, entrypoint in [('game', 'AM2R-project.yyp'), ('autopatcher', 'linux_patcher.py')]:
            manifest = copy.deepcopy(fixture.manifest)
            manifest.update(project_kind=kind, project_file=entrypoint)
            manifest['source_files'][0]['path'] = entrypoint
            if kind == 'autopatcher':
                manifest.update(platform='linux', edition=kind, bundle_path='patcher-assets')
            archive = fixture.root / (kind + '.zip')
            with zipfile.ZipFile(archive, 'w') as z:
                z.writestr('project/asset-inputs.json', json.dumps(manifest))
                z.writestr('project/' + entrypoint, (fixture.project / 'AM2R-project.yyp').read_bytes())
                z.writestr('project/code.gml', (fixture.project / 'code.gml').read_bytes())
            target = fixture.root / kind
            with zipfile.ZipFile(archive) as z:
                z.extractall(target)
            projects.append(target / 'project')
            releases.append(dict(name=archive.name, tag='fixture', url='https://example.com/' + archive.name,
                                 sha256=tool.digest_file(archive)))
        donor = fixture.root / 'donor'
        for row in fixture.manifest['files']:
            path = donor / row['path']
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(fixture.music if row['path'].startswith('sounds/') else fixture.asset)
        output = fixture.root / 'rebuilt'
        with mock.patch.object(builder, 'ORIGINAL', fixture.description['source']):
            builder.build(fixture.root, releases, [donor], fixture.original, output)
        for project in projects:
            result = tool.restore(project, fixture.original, output / 'bundle')
            self.assertEqual(result['restored'], 3)
            self.assertFalse(result['missing_assets'])
            self.assertFalse(result['modified_source'])
