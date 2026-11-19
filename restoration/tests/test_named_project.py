"""Native project names use the same verified restore flow as Android."""
import json
from pathlib import Path
import sys
import unittest
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from test_restore import RestoreTests
import restore_project as tool
import build_catalog as catalog


class NamedProjectTests(RestoreTests):
    def setUp(self):
        super().setUp()
        self.name = 'AM2RDualLinux.yyp'
        (self.project / 'AM2R-project.yyp').rename(self.project / self.name)
        self.manifest['source_files'][0]['path'] = self.name
        self.manifest.update(project_file=self.name, platform='linux')
        self.manifest['generated_inputs'] = [{'path': 'extensions/AM2RThor/libAM2RThor.so',
            'size': 4, 'sha256': '0' * 64, 'build_from': 'native/linux-display.c'}]
        self.save_manifest()

    def test_named_project_restores_and_reports_generated_input(self):
        result = self.restore()
        self.assertEqual(result['restored'], 3)
        self.assertEqual(result['project_file'], self.name)
        self.assertEqual(result['generated_inputs'], self.manifest['generated_inputs'])
        self.assertEqual(result['missing_generated'], ['extensions/AM2RThor/libAM2RThor.so'])
        self.assertEqual(tool.inspect_project(self.project, self.bundle)['missing_source'], [])

    def test_catalog_retains_platform_and_project_file(self):
        archive = self.root / 'source.zip'
        with zipfile.ZipFile(archive, 'w') as output:
            for p in self.project.iterdir():
                output.writestr('AM2R-project/' + p.name, p.read_bytes())
        release = {'tag': 'fixture', 'name': archive.name, 'url': '', 'sha256': tool.digest_file(archive)}
        description, replacements = catalog.read_export(archive, release)
        self.assertEqual(description['project_file'], self.name)
        self.assertEqual(description['platform'], 'linux')
        self.assertEqual(description['generated_inputs'], self.manifest['generated_inputs'])
        self.assertFalse(replacements)

    def test_project_reference_must_be_root_yyp(self):
        for name in ['../escape.yyp', 'sub/other.yyp', 'code.gml', 'missing.yyp']:
            with self.subTest(name=name):
                self.manifest['project_file'] = name
                self.save_manifest()
                with self.assertRaises(tool.RestoreError):
                    self.restore()
                self.assertFalse((self.project / 'sprites').exists())

    def test_generated_input_must_not_overlap_a_source(self):
        self.manifest['generated_inputs'][0]['path'] = 'code.gml'
        self.save_manifest()
        with self.assertRaises(tool.RestoreError):
            self.restore()
        self.assertFalse((self.project / 'sprites').exists())


if __name__ == '__main__':
    unittest.main()
