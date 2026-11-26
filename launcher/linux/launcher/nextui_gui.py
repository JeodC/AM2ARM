"""Run the shared edition picker on a direct-display firmware."""
from pathlib import Path
import os
import tkinter as tk
import handheld_gui
import handheld_input
from trimui_device import firmware_face_buttons
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
    auto = os.environ.get('AM2ARM_FIRST_RUN') == '1'
    notice = os.environ.get('AM2ARM_DISPLAY_NOTICE')
    if notice == 'dual-screen':
        title = 'DUAL SCREEN INSTALLED'
        message = ('This display driver can show one screen. To play here, open '
                   'AM2ARM and choose Standard. Your Dual Screen installation stays on the card.')
        result = 0
    elif notice == 'westonpack' and not (auto and os.environ.get('AM2ARM_FETCH_DISPLAY') == '1'):
        from weston_graphics import SETUP_MESSAGE
        title, message, result = 'DISPLAY SETUP', SETUP_MESSAGE, 2
    else:
        notice = None
    if notice:
        window = StandardWindow(root, size=display_size())
        root.wait_visibility()
        window.finish_intro()
        window.notice = handheld_gui.Notice(root, title, message, window.close)
        root.mainloop()
        return result
    if auto:
        from first_run import Library
        from first_run_gui import PlayWindow
        window = PlayWindow(root, Library.from_environment(), True, display_size())
        root.mainloop()
        return 0 if window.play else 2
    card = Path(os.environ.get('SDCARD_PATH', '/mnt/SDCARD'))
    output = card/'AM2ARM/games'
    if (output/'AM2ARM Standard').exists() or (output/'AM2ARM Standard.sh').exists():
        output = output/'1.6.3'
    StandardWindow(root, output=output, size=display_size(), install_func=prepare_game,
                menu_name=os.environ.get('AM2ARM_MENU_NAME', 'Apps'))
    root.mainloop()


if __name__ == '__main__':
    raise SystemExit(main())
