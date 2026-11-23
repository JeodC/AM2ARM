"""The first launch uses the existing handheld UI and its controller picker."""
from first_run import find_original
from handheld_gui import FilePicker, HandheldWindow


class PlayWindow(HandheldWindow):
    def __init__(self, root, library, single, size=None):
        self.library = library
        self.single = single
        self.chosen = single
        self.play = False
        self.initialized = False
        super().__init__(root, library.output, size, install_func=library.install)
        self.source = find_original(library.app, library.card, library.ports)
        self.standard.configure(text='PLAY STANDARD')
        self.dual.configure(text='PLAY DUAL SCREEN')
        self.status.set('Preparing Standard Edition…' if single else 'Choose an edition to play.')
        self.initialized = True
        self.layout()

    def render_intro(self):
        super().render_intro()
        self.folder.set_visible(False)
        self.install.set_visible(False)
        if self.single:
            self.dual.set_visible(False)

    def finish_intro(self):
        first = self.intro_active
        super().finish_intro()
        if first and self.single:
            self.select_edition('standard')

    def select_edition(self, edition):
        super().select_edition(edition)
        if not self.initialized:
            return
        self.chosen = True
        self.focus_index = 0 if edition == 'standard' else 1
        if self.library.existing(edition):
            self.begin(check_existing=True)
        else:
            self.begin()

    def browse(self, folders=False):
        if not self.busy:
            start = self.source.parent if self.source else self.library.card
            self.picker = FilePicker(self.root, start, False, self.picked, self.beep)

    def picked(self, path, folders):
        self.picker = None
        if path is not None:
            self.source = path
            self.status.set(path.name)
            if self.chosen:
                self.begin()
        elif not self.busy:
            self.status.set('Select your original Windows AM2R 1.1 ZIP.')

    def action(self, action):
        if not (self.intro_active or self.busy or self.picker or self.notice):
            if action == 'folder':
                return
            if action in ('up', 'down', 'left', 'right'):
                visible = (0, 2) if self.single else (0, 1, 2)
                delta = -1 if action in ('up','left') else 1
                self.focus_index = visible[(visible.index(self.focus_index) + delta) % len(visible)]
                self.highlight()
                self.beep()
                return
        super().action(action)

    def installed(self, game, digest):
        if digest:
            super().installed(game, digest)
        self.play = True
        self.close()

    def dismiss_notice(self):
        super().dismiss_notice()
        self.source = None
        self.focus_index = 0 if self.edition == 'standard' else 1
        self.status.set('Select your original Windows AM2R 1.1 ZIP.')
        self.layout()
