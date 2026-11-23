import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import nextui_session

SOURCE = Path(__file__).resolve().parents[3]


def load_launcher():
    spec = importlib.util.spec_from_file_location('standard_game', SOURCE/'native/linux/runtime/launch.py')
    launcher = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(launcher)
    return launcher


class InitialDisplay(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        self.config = self.root/'config.ini'

    def test_direct_standard_leaves_fresh_display_defaults_to_the_game(self):
        game = self.root/'Standard'
        (game/'runtime').mkdir(parents=True)
        (game/'data').mkdir()
        (game/'runtime/launch.py').symlink_to(SOURCE/'native/linux/runtime/launch.py')
        (game/'edition.json').write_text(json.dumps(dict(edition='standard', game_name='AM2RStandardLinux')))
        (game/'data/gamecontrollerdb.txt').write_text('')
        with patch.dict(os.environ, HOME=str(self.root), AM2ARM_FRONTEND='spruce'):
            folder, _ = nextui_session.game_options(game,'smartpros')
        contents=(folder/'config.ini').read_text()
        self.assertIn('[Screen]', contents)
        self.assertNotIn('Scale=', contents)
        self.assertNotIn('AspectRatio=', contents)

    def test_ports_standard_uses_the_game_defaults_only_on_a_single_panel(self):
        game=load_launcher()
        game.prepare_display_config(self.config,'standard',True)
        self.assertNotIn('AspectRatio=',self.config.read_text())
        self.config.unlink()
        game.prepare_display_config(self.config,'standard',False)
        self.assertIn('AspectRatio=0',self.config.read_text())

    def test_dual_profile_and_existing_settings_survive(self):
        game=load_launcher()
        game.prepare_display_config(self.config,'dual-screen',True)
        self.assertIn('[DualScreen]\nDeviceProfile=1\nSwapScreens=0',self.config.read_text())
        original=b'[Screen]\r\nAspectRatio="2"\r\nNano=1\r\n[Control]\r\nCustom=1\r\n'
        self.config.write_bytes(original)
        game.prepare_display_config(self.config,'standard',True)
        self.assertEqual(self.config.read_bytes(),original)
