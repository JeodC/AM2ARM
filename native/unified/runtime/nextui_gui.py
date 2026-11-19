"""Single-screen entry point for the shared installer."""
from pathlib import Path
import os
import tkinter as tk
import handheld_gui
import handheld_input
from nextui_controls import firmware_face_buttons
from trimui_device import display_size
from nextui_install import prepare_game

original_faces = handheld_input.firmware_face_buttons


def device_faces(name, ids, keys, paths=None):
    return firmware_face_buttons(name, ids, keys, paths) or original_faces(name, ids, keys, paths)


handheld_input.firmware_face_buttons = device_faces


class StandardWindow(handheld_gui.HandheldWindow):
    def render_intro(self):
        super().render_intro()
        self.dual.set_visible(False)

    def action(self, action):
        super().action(action)
        if not self.closed and self.picker is None and self.notice is None and self.focus_index == 1:
            self.focus_index = 0 if action in ('up', 'left') else 2
            self.highlight()


def main():
    root = tk.Tk()
    root.overrideredirect(True)
    card = Path(os.environ.get('SDCARD_PATH', '/mnt/SDCARD'))
    output = card/'AM2ARM/games'
    if (output/'AM2ARM Standard').exists() or (output/'AM2ARM Standard.sh').exists():
        output = output/'1.6.2'
    StandardWindow(root, output=output, size=display_size(), install_func=prepare_game,
                menu_name=os.environ.get('AM2ARM_MENU_NAME', 'Apps'))
    root.mainloop()


if __name__ == '__main__':
    main()
