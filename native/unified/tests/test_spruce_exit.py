import os
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from handheld_input import EVENT
from spruce_exit import SpruceMenuExit


class MenuExit(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.card = Path(temporary.name)
        self.config = self.card/'Saves/spruce/spruce-config.json'
        self.config.parent.mkdir(parents=True)
        self.device = self.card/'event4'
        os.mkfifo(self.device)

    def open_menu(self, tap='Exit game', hold='Game Switcher'):
        self.config.write_text(json.dumps({'menuOptions': {'Button Settings': {
            'tapMenuAction': {'selected':tap}, 'holdMenuAction': {'selected':hold},
            'menuHoldTime': {'selected':'1'}}}}))
        return SpruceMenuExit.open(self.card, self.device, 316)

    def feed(self, records):
        with self.device.open('wb',buffering=0) as fd:
            for seconds,code,value in records:
                whole=int(seconds)
                fd.write(EVENT.pack(whole,round((seconds-whole)*1_000_000),1,code,value))

    def test_requested_menu_tap_quits_on_release_once(self):
        with self.open_menu() as menu:
            self.feed([(1,316,1),(1.17,316,0)])
            self.assertTrue(menu.requested())
            self.assertFalse(menu.requested())

    def test_long_press_and_combinations_preserve_other_firmware_actions(self):
        with self.open_menu() as menu:
            self.feed([(2,316,1),(4,316,0),(5,316,1),(5.1,304,1),(5.2,316,0)])
            self.assertFalse(menu.requested())
        self.assertIsNone(self.open_menu('Screenshot','Game Switcher'))

    def test_firmware_button_encoding_and_separate_volume_device(self):
        with self.open_menu():
            pass
        volume = self.card/'volume'
        os.mkfifo(volume)
        with patch.dict(os.environ, B_MENU='1 316'):
            with SpruceMenuExit.open(self.card, self.device, volume=volume) as menu:
                self.feed([(1,316,1), (1.2,316,0)])
                with volume.open('wb', buffering=0) as fd:
                    fd.write(EVENT.pack(1,100_000,1,115,1))
                    fd.write(EVENT.pack(1,180_000,1,115,0))
                self.assertFalse(menu.requested())
                self.feed([(2,316,1), (2.2,316,0)])
                self.assertTrue(menu.requested())

    def test_hold_only_exit_and_lost_events(self):
        with self.open_menu('Emulator menu','Exit game') as menu:
            self.feed([(1,316,1),(1.3,316,0)])
            self.assertFalse(menu.requested())
            self.feed([(2,316,1),(3.2,316,0)])
            self.assertTrue(menu.requested())
            self.feed([(4,316,1)])
            with self.device.open('wb',buffering=0) as fd:
                fd.write(EVENT.pack(4,300_000,0,3,0))
            self.feed([(6,316,0)])
            self.assertFalse(menu.requested())

    def test_configured_hold_closes_while_still_pressed_only_once(self):
        with self.open_menu('Emulator menu','Exit game') as menu:
            with patch('time.monotonic',return_value=100):
                self.feed([(4,316,1)])
                self.assertFalse(menu.requested())
            with patch('time.monotonic',return_value=101.1):
                self.assertTrue(menu.requested())
                self.feed([(5.2,316,0)])
                self.assertFalse(menu.requested())

    def test_menu_with_hat_or_trigger_preserves_the_firmware_shortcut(self):
        with self.open_menu() as menu:
            for axis, value in ((16, -1), (17, 1), (2, 255), (5, 255)):
                with self.subTest(axis=axis), self.device.open('wb',buffering=0) as fd:
                    fd.write(EVENT.pack(1,0,1,316,1))
                    fd.write(EVENT.pack(1,50_000,3,axis,value))
                    fd.write(EVENT.pack(1,90_000,3,axis,0))
                    fd.write(EVENT.pack(1,120_000,1,316,0))
                    self.assertFalse(menu.requested())

    def test_missing_settings_or_inaccessible_input_is_optional(self):
        self.assertIsNone(SpruceMenuExit.open(self.card,self.device,316))
        self.device.unlink()
        self.assertIsNone(self.open_menu())
