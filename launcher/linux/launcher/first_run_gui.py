"""Select and play an edition from the handheld's single launcher entry."""
import os
from zipfile import BadZipFile

from first_run import ORIGINAL_FOLDER, find_original, remembered_edition, retire_edition_entries
from handheld_gui import FilePicker, HandheldWindow, Notice
from handheld_visuals import CanvasButton
from menu_entries import write_text
from patch_core import OriginalZipError, PatchError


class EditionButton(CanvasButton):
    def paint(self):
        super().paint()
        x, y, width, height = self.bounds
        # The menu font's capitals occupy five pixels of each 13-pixel em, up to the baseline.
        cap_height = abs(self.font[1]) * 5 // 13
        ascent = int(self.canvas.tk.call("font", "metrics", self.font, "-ascent"))
        linespace = int(self.canvas.tk.call("font", "metrics", self.font, "-linespace"))
        baseline = y + (height + cap_height) // 2
        self.canvas.coords(self.text_item, x + width / 2, baseline - ascent + linespace // 2)
        self.canvas.itemconfigure(self.text_item, anchor="center")


class PlayWindow(HandheldWindow):
    def __init__(self, root, library, single, size=None):
        self.library = library
        self.play = self.ready = False
        self.input_rejected = False
        super().__init__(root, library.output, size, install_func=self.install_edition)
        root.title("AM2ARM Launcher")
        self.canvas.itemconfigure(self.subtitle, text=f"LAUNCHER  {library.version}")
        for button in self.buttons[2:]:
            self.canvas.delete(button.border_item, button.text_item)
        del self.buttons[2:]
        del self.button_windows[2:]
        self.direct = os.environ.get("AM2ARM_DISPLAY_PATH") == "direct"
        self.update_edition_labels()
        self.status.set("Hold D-pad Up at launch to change edition.")
        self.ready = True
        self.previous_choice = remembered_edition(library)
        suggested = self.previous_choice or ("standard" if single else "dual")
        self.focus_edition("standard" if self.direct else suggested)

    def update_edition_labels(self):
        for edition, label, button in (("standard", "STANDARD", self.standard),
                                       ("dual", "DUAL SCREEN", self.dual)):
            installed = self.library.existing(edition) is not None
            if installed and edition == "dual" and self.direct:
                text = "DUAL SCREEN INSTALLED"
            else:
                text = ("PLAY " if installed else "INSTALL ") + label
            button.configure(text=text)

    def button(self, text, command, y, width=344, x=16):
        rows = {"STANDARD": 244, "DUAL SCREEN": 282}
        if text not in rows:
            return super().button(text, command, y, width, x)
        button = EditionButton(self.canvas, text, lambda: self.activate(command), self.menu_font)
        self.buttons.append(button)
        self.button_windows.append((button, x, rows[text], width))
        return button

    def layout(self):
        super().layout()
        self.canvas.coords(self.help, self.width / 2, round(self.origin + 324 * self.scale))
        self.canvas.itemconfigure(self.help, anchor="n", justify="center")

    def render_intro(self):
        super().render_intro()
        if not self.busy:
            self.canvas.itemconfigure(self.meter, state="hidden")
            self.canvas.itemconfigure(self.fill, state="hidden")

    def draw_progress(self):
        super().draw_progress()
        if self.busy:
            self.canvas.itemconfigure(self.meter, state="normal")
            self.canvas.itemconfigure(self.fill, state="normal")

    def focus_edition(self, edition):
        self.focus_index = 0 if edition == "standard" else 1
        super().select_edition(edition)
        if self.direct and edition == "dual":
            self.canvas.itemconfigure(self.help, text="For a two-screen setup. Standard plays here.")

    def action(self, action):
        if not (self.intro_active or self.busy or self.picker or self.notice):
            if action in ("up", "down", "left", "right"):
                self.focus_edition("dual" if self.focus_index == 0 else "standard")
                self.beep()
                return
            if action == "folder":
                return
        super().action(action)

    def select_edition(self, edition):
        if not self.ready:
            return
        self.focus_edition(edition)
        try:
            game = self.library.existing(edition)
            if game is not None:
                if self.direct and edition == "dual":
                    self.installed(game, None)
                    return
                if remembered_edition(self.library) != edition:
                    write_text(self.library.choice, edition + "\n")
                self.installed(game, None)
                return
        except OSError as error:
            self.messages.put(("error", str(error)))
            return
        self.source = find_original(self.library.app, self.library.card, self.library.ports)
        self.begin()

    def browse(self, folders=False):
        if self.busy:
            return
        start = self.source.parent if self.source else self.library.card / ORIGINAL_FOLDER
        if not start.is_dir():
            start = self.library.card
        self.picker = FilePicker(self.root, start, False, self.picked, self.beep)

    def install_edition(self, source, output, edition, progress):
        try:
            return self.library.install(source, output, edition, progress)
        except (OriginalZipError, BadZipFile):
            self.input_rejected = True
            raise
        except (OSError, PatchError):
            self.input_rejected = not source.is_file()
            raise

    def picked(self, path, folders):
        self.picker = None
        self.source = path
        if path is not None:
            self.begin()
        else:
            self.status.set("")
            self.layout()

    def installed(self, game, digest):
        if digest:
            super().installed(game, digest)
        retire_edition_entries(self.library.card)
        if self.direct and self.edition == "dual":
            # The shared installer records the edition it just built. Keep a prior
            # playable choice when this copy was prepared for another display.
            if self.previous_choice == "standard" and remembered_edition(self.library) == "dual":
                try:
                    write_text(self.library.choice, "standard\n")
                except OSError as error:
                    self.messages.put(("error", str(error)))
            self.update_edition_labels()
            self.focus_edition("standard")
            self.notice = Notice(self.root, "DUAL SCREEN INSTALLED",
                                 "Dual Screen is ready for a two-screen setup. Choose Standard to play here.",
                                 self.dismiss_notice)
            return
        self.play = True
        self.close()

    def dismiss_notice(self):
        super().dismiss_notice()
        self.status.set("")
        self.layout()
        if self.input_rejected:
            self.input_rejected = False
            self.browse()
