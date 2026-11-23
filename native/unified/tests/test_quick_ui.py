import os
from pathlib import Path
import tempfile
import tkinter as tk
import unittest
from unittest.mock import patch

from first_run import Library
from first_run_gui import PlayWindow
from test_first_run import donor_at, game_at, write_manifests


@unittest.skipUnless(os.environ.get('DISPLAY'), 'needs a desktop display')
class QuickUiTests(unittest.TestCase):
    def window(self, single, donor=True):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        card = Path(tmp.name)
        write_manifests(card/'am2arm-launcher')
        self.library = Library(card/'am2arm-launcher', card, card/'ports')
        self.donor = donor_at(card/'AM2R_11.zip') if donor else None
        self.root = tk.Tk()
        window = PlayWindow(self.root, self.library, single, (640,480))
        self.addCleanup(lambda: window.close() if not window.closed else None)
        return window

    def test_single_starts_without_any_confirmation(self):
        win = self.window(True)
        with patch.object(win,'begin') as begin:
            win.finish_intro()
            win.finish_intro()
            begin.assert_called_once_with()
            self.assertEqual(win.source, self.donor)
        self.assertFalse(win.dual.visible)
        self.assertFalse(win.folder.visible)

    def test_dual_screen_needs_only_one_edition_confirmation(self):
        win = self.window(False)
        with patch.object(win,'begin') as begin:
            win.finish_intro()
            begin.assert_not_called()
            win.action('down')
            win.action('accept')
            self.assertEqual(win.edition, 'dual')
            begin.assert_called_once_with()

    def test_missing_original_opens_card_picker_and_cancel_does_not_install(self):
        win = self.window(True, False)
        win.finish_intro()
        self.assertEqual(win.picker.path, self.library.card)
        win.action('back')
        self.assertIsNone(win.picker)
        self.assertFalse(win.busy)
        win.action('accept')
        self.assertIsNotNone(win.picker)
        with patch.object(win,'begin') as begin:
            source = donor_at(self.library.card/'backup.zip')
            win.picker.finish(source)
            self.assertEqual(win.source,source)
            begin.assert_called_once_with()

    def test_switch_to_an_installed_edition_with_no_original(self):
        win = self.window(False, False)
        game_at(self.library.ports/'AM2ARM Dual Screen','dual-screen')
        win.finish_intro()
        win.action('down')
        win.action('accept')
        message = win.messages.get(timeout=3)
        while message[0] == 'progress':
            message = win.messages.get(timeout=3)
        win.messages.put(message)
        win.poll()
        self.assertTrue(win.play)
        self.assertTrue(win.closed)
        self.assertEqual(self.library.choice.read_text().strip(),'dual')

    def test_success_opens_game_and_error_allows_retry(self):
        win = self.window(True)
        with patch.object(win, 'begin'):
            win.finish_intro()
        win.messages.put(('error','Wrong original file'))
        win.poll()
        self.assertFalse(win.closed)
        self.assertIsNotNone(win.notice)
        win.action('accept')
        self.assertIsNone(win.source)
        win.action('accept')
        self.assertIsNotNone(win.picker)
        win.picker.back()
        win.messages.put(('done',self.library.output/'AM2ARM Standard','abcd'))
        win.poll()
        self.assertTrue(win.play)
        self.assertTrue(win.closed)
