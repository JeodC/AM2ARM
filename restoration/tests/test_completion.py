"""Completion text identifies the actual project and remaining build inputs."""
import unittest
import restore_project as tool


class CompletionTests(unittest.TestCase):
    def result(self, **changes):
        value = dict(restored=3, modified_source=['code.gml'],
                     project_file='AM2RDualLinux.yyp', project_kind='game',
                     missing_generated=[], different_generated=[])
        value.update(changes)
        return value

    def test_native_game_names_its_actual_entrypoint(self):
        message = tool.completion_message(self.result())
        self.assertIn('AM2RDualLinux.yyp', message)
        self.assertIn('1 source edits preserved', message)
        self.assertNotIn('AM2R-project.yyp', message)

    def test_generated_inputs_are_not_claimed_as_restored(self):
        message = tool.completion_message(self.result(missing_generated=['display.so']))
        self.assertIn('1 generated build inputs remain', message)

    def test_patcher_is_not_sent_to_gamemaker(self):
        message = tool.completion_message(self.result(project_file='linux_patcher.py',
            project_kind='autopatcher', different_generated=['bundle.json']))
        self.assertIn('linux_patcher.py', message)
        self.assertNotIn('GameMaker', message)
        self.assertIn('README.txt', message)
