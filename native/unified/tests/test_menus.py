import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

from menu_entries import install_play_entry, stage_patcher_entries
from nextui_layout import installed_game, write_play_entry, stock_save_directory
from route import choose_backend


class Layout(unittest.TestCase):
    def test_supported_ports_use_session_and_direct_boards_fall_back(self):
        def unknown():
            raise RuntimeError('unknown board')
        def no_session(env):
            raise RuntimeError('missing socket')
        self.assertEqual(choose_backend('ports', {}, lambda e:e, unknown), 'ports')
        self.assertEqual(choose_backend('ports', {}, no_session, lambda:'flip'), 'direct')
        self.assertEqual(choose_backend('spruce', {}, no_session, lambda:'smartpros'), 'direct')
        with self.assertRaisesRegex(RuntimeError, 'compatibility.txt'):
            choose_backend('ports', {}, no_session, unknown)

    def test_menu_scripts_find_one_payload_from_paths_with_spaces(self):
        with tempfile.TemporaryDirectory() as tmp:
            card=Path(tmp)/'Game Card'; app=card/'AM2ARM';app.mkdir(parents=True)
            (app/'launch.sh').write_text('#!/bin/sh\nprintf "%s %s" "$AM2ARM_FRONTEND" "$1"\n')
            stage_patcher_entries(card)
            for rel,frontend in [('ports/AM2ARM Autopatcher.sh','ports'),('Roms/ports/AM2ARM Autopatcher.sh','ports'),('Tools/tg5040/AM2ARM Autopatcher.pak/launch.sh','nextui'),('Tools/my355/AM2ARM Autopatcher.pak/launch.sh','tools'),('App/AM2ARMAutopatcher/launch.sh','spruce'),('Apps/AM2ARMAutopatcher/launch.sh','stock')]:
                with self.subTest(rel=rel):
                    cmd=card/rel
                    self.assertEqual(subprocess.check_output(['sh',cmd], text=True),frontend+' patcher')
            self.assertTrue((card/'App/AM2ARMAutopatcher/config.json').is_file())
            self.assertFalse((card/'ports/AM2ARM Standard.sh').exists())

    def test_existing_state_and_custom_entries_are_preserved(self):
        with tempfile.TemporaryDirectory() as tmp:
            card=Path(tmp); old=card/'AM2ARM/games/AM2ARM Standard'; newer=card/'AM2ARM/games/1.6.2/AM2ARM Standard'
            state=card/'AM2ARM/state/installation.json'; state.parent.mkdir(parents=True)
            oldsave=old/'state/config/AM2RStandardLinux';oldsave.mkdir(parents=True);(oldsave/'save1').write_bytes(b'previous')
            state.write_text(json.dumps({'game':old.relative_to(card).as_posix()}));newer.mkdir(parents=True)
            with patch.dict(os.environ,AM2ARM_FRONTEND='stock',SDCARD_PATH=str(card)):
                write_play_entry(card,newer)
                self.assertEqual(installed_game(card),newer)
                self.assertEqual(stock_save_directory(card,newer),oldsave)
                self.assertEqual((oldsave/'save1').read_bytes(),b'previous')
                self.assertTrue((card/'Apps/AM2ARMStandard/launch.sh').is_file())
            bad=card/'ports/AM2ARM Standard.sh';bad.parent.mkdir();bad.write_text('#!/bin/sh\ncustom\n')
            with patch.dict(os.environ, AM2ARM_FRONTEND='ports', AM2ARM_PORTS_DIR=str(bad.parent)):
                with self.assertRaises(RuntimeError): install_play_entry(card, newer)
                self.assertIn('custom',bad.read_text())
