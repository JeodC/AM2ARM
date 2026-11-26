"""Exercise the launcher with the installation modules from the 1.6.3 package."""

import csv
from contextlib import redirect_stdout
import hashlib
import importlib
import io
import os
from pathlib import Path
import runpy
import subprocess
import sys
from tempfile import TemporaryDirectory
from types import ModuleType
import unittest
from unittest.mock import patch
from zipfile import ZipFile
from test_launcher_art import LauncherArtChecks

PROTOTYPE = Path(__file__).parent / "launcher"
BASE = os.environ.get("AM2ARM_BASE_ZIP")


def setUpModule():
    global lookup, routes, windows, released, work
    from build_launcher import adapt_display_session, classify_original_zip_errors, respect_completion_notice
    if not BASE:
        raise RuntimeError("Set AM2ARM_BASE_ZIP to the verified 1.6.3 standalone ZIP.")
    work = TemporaryDirectory()
    unittest.addModuleCleanup(work.cleanup)
    released = Path(work.name)
    with ZipFile(BASE) as archive:
        for entry in archive.namelist():
            prefix, _, name = entry.rpartition("/")
            if prefix in ("am2arm-launcher/AM2ARM/runtime", "am2arm-launcher/AM2ARM/patcher") and name.endswith(".py"):
                (released / name).write_bytes(archive.read(entry))
        (released / "installation.py").write_bytes((released / "first_run.py").read_bytes())
        session = released / "nextui_session.py"
        session.write_bytes(adapt_display_session(session.read_bytes()))
        core = released / "patch_core.py"
        core.write_bytes(classify_original_zip_errors(core.read_bytes()))
        gui = released / "handheld_gui.py"
        gui.write_bytes(respect_completion_notice(gui.read_bytes()))
        for entry in archive.namelist():
            if "/patcher/assets/" in entry and not entry.endswith("/"):
                target = released / "assets" / entry.split("/patcher/assets/", 1)[1]
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(archive.read(entry))
    sys.path[:0] = [str(PROTOTYPE), str(released)]
    lookup = importlib.import_module("first_run")
    routes = importlib.import_module("route")
    windows = importlib.import_module("first_run_gui")


class PlayerFlow(LauncherArtChecks, unittest.TestCase):
    def setUp(self):
        tmp = TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.card = Path(tmp.name)
        self.app = self.card / "am2arm-launcher/AM2ARM"
        self.ports = self.card / "ports"

    def original(self, name):
        path = self.card / name
        path.parent.mkdir(parents=True, exist_ok=True)
        with ZipFile(path, "w") as archive:
            archive.writestr("Game/AM2R.exe", b"fixture")
            archive.writestr("Game/data.win", b"fixture")
        return path

    def source(self):
        return lookup.find_original(self.app, self.card, self.ports)

    def packaged_graphics(self, archive):
        name = "am2arm-launcher/AM2ARM/runtime/weston_graphics.py"
        module = ModuleType("packaged_graphics")
        module.__file__ = str(self.app / "runtime/weston_graphics.py")
        exec(compile(archive.read(name), name, "exec"), module.__dict__)
        return module

    def test_renamed_original_inside_visible_game_folder(self):
        path = self.original("AM2ARM/My backup.ZIP")
        (self.card / "AM2ARM/corrupt.zip").write_bytes(b"interrupted transfer")
        self.assertEqual(self.source(), path)

    def test_renamed_original_beside_game_folder(self):
        self.assertEqual(self.original("1.1.zip"), self.source())

    def test_ambiguous_archives_go_to_picker(self):
        self.original("AM2ARM/one.zip")
        self.original("AM2ARM/two.zip")
        self.assertIsNone(self.source())

    def test_visible_original_wins_over_an_older_copy(self):
        self.original("ports/AM2R_11.zip")
        self.assertEqual(self.original("AM2ARM/my original.zip"), self.source())

    def test_two_fallback_copies_still_need_the_picker(self):
        self.original("AM2R_11.zip")
        self.original("Downloads/backup.zip")
        self.assertIsNone(self.source())

    def test_legacy_input_still_works(self):
        self.assertEqual(self.original("am2arm-launcher/AM2ARM/patcher/input/backup.zip"), self.source())

    def test_mounted_runtime_finds_original_at_physical_launcher(self):
        self.app = self.card / "private-mount/am2arm-launcher/AM2ARM"
        self.assertEqual(self.original("am2arm-launcher/backup.zip"), self.source())

    @unittest.skipUnless(os.environ.get("AM2ARM_LAUNCHER_ZIP"), "Set AM2ARM_LAUNCHER_ZIP to check firmware entries.")
    def test_packaged_menu_entries_share_the_visible_source_folder(self):
        entrypoints = ("ports/AM2ARM.sh", "roms/ports/AM2ARM.sh", "Tools/tg5040/AM2ARM.pak/launch.sh",
                       "Tools/tg5050/AM2ARM.pak/launch.sh", "Tools/my355/AM2ARM.pak/launch.sh",
                       "Apps/AM2ARM/launch.sh", "App/AM2ARM/launch.sh")
        library = self.card / "Games on card 2"
        runner = library / "am2arm-launcher/launch.sh"
        runner.parent.mkdir(parents=True)
        runner.write_text('printf "%s\\n" "$AM2ARM_GAME_CARD" "$1"\n')
        original = self.original("Games on card 2/AM2ARM/1.1.zip")
        with ZipFile(os.environ["AM2ARM_LAUNCHER_ZIP"]) as archive:
            for entry in entrypoints:
                with self.subTest(entry=entry):
                    script = Path(archive.extract(entry, library))
                    root, action = subprocess.check_output(["sh", script], cwd=self.card, text=True).splitlines()
                    self.assertEqual((Path(root), action), (library, "auto"))
                    self.assertEqual(lookup.find_original(runner.parent / "AM2ARM", Path(root), script.parent), original)
            guide = archive.read("AM2ARM/README.txt").decode()
            self.assertIn("Windows AM2R 1.1 ZIP", guide)

    def test_missing_or_ambiguous_original_opens_picker_at_source_folder(self):
        import tkinter as tk
        from types import SimpleNamespace
        library = SimpleNamespace(output=self.card, app=self.app, card=self.card, ports=self.ports,
                                  choice=self.card/"edition.txt", version="1.6.3",
                                  existing=lambda edition: None, install=None)
        (self.card/"AM2ARM").mkdir()
        window = windows.PlayWindow(tk.Tk(), library, True, (640, 480))
        self.addCleanup(window.close)
        window.finish_intro()
        window.action("accept")
        self.assertEqual(window.picker.path, self.card/"AM2ARM")
        window.action("back")
        self.assertIsNone(window.picker)
        self.original("AM2ARM/one.zip")
        self.original("AM2ARM/two.zip")
        window.action("down")
        window.action("accept")
        self.assertEqual([path.name for path, action in window.picker.entries if action == "open"],
                         ["one.zip", "two.zip"])
        window.action("back")
        self.assertEqual((window.focus_index, window.edition), (1, "dual"))

    def test_two_centered_choices_wrap_and_follow_the_controller(self):
        import tkinter as tk
        from types import SimpleNamespace
        library = SimpleNamespace(output=self.card, app=self.app, card=self.card, ports=self.ports,
                                  choice=self.card/"edition.txt", version="1.6.3",
                                  existing=lambda edition: None, install=None)
        for w, h in ((640, 480), (1024, 768), (1280, 720)):
            with self.subTest(panel=(w, h)):
                window = windows.PlayWindow(tk.Tk(), library, True, (w, h))
                try:
                    window.finish_intro()
                    self.assertEqual([b for b in window.buttons if b.visible], [window.standard, window.dual])
                    for button in (window.standard, window.dual):
                        self.assertAlmostEqual(window.canvas.coords(button.text_item)[0], w/2, delta=1)
                        self.assertEqual(window.canvas.itemcget(button.text_item, "anchor"), "center")
                    top = window.standard.bounds[1]
                    help_bottom = window.canvas.bbox(window.help)[3]
                    subtitle_bottom = window.canvas.bbox(window.subtitle)[3]
                    progress_top = window.canvas.coords(window.meter)[1]
                    self.assertAlmostEqual(top-subtitle_bottom, progress_top-help_bottom, delta=12*h/480)
                    for action, index in (("down", 1), ("down", 0), ("up", 1), ("right", 0)):
                        window.action(action)
                        self.assertEqual(window.focus_index, index)
                        self.assertIn("Map" if index else "single", window.canvas.itemcget(window.help, "text"))
                finally:
                    window.close()

    def test_rejected_original_returns_to_picker_and_accepts_a_replacement(self):
        import tkinter as tk
        import time
        from types import SimpleNamespace
        from patch_core import locate_datawin

        good_data = b"verified game data"
        used = []
        def install(source, output, edition, progress):
            used.append(source.name)
            data = locate_datawin(source, hashlib.sha256(good_data).hexdigest(), progress, self.card)
            data.unlink()
            return self.card/edition, None

        def until(predicate):
            deadline = time.monotonic() + 5
            while not predicate() and time.monotonic() < deadline:
                window.root.update()
                time.sleep(.01)
            self.assertTrue(predicate())

        self.original("AM2ARM/wrong.zip")
        library = SimpleNamespace(output=self.card, app=self.app, card=self.card, ports=self.ports,
                                  choice=self.card/"edition.txt", version="1.6.3", install=install,
                                  existing=lambda edition: None)
        window = windows.PlayWindow(tk.Tk(), library, True, (640, 480))
        try:
            window.finish_intro()
            window.action("accept")
            until(lambda: window.notice is not None)
            self.assertIn("original", window.notice.body.get("1.0", "end").lower())
            with ZipFile(self.card/"AM2ARM/right.zip", "w") as good:
                good.writestr("AM2R.exe", b"fixture")
                good.writestr("data.win", good_data)
            window.action("accept")
            self.assertEqual(window.picker.path, self.card/"AM2ARM")
            window.action("down")  # From the parent-folder entry to right.zip.
            window.action("accept")
            until(lambda: window.closed)
            self.assertTrue(window.play)
            self.assertEqual(used, ["wrong.zip", "right.zip"])
        finally:
            if not window.closed:
                window.close()

    def test_playing_an_installed_edition_from_menu_skips_patching_and_remembers_it(self):
        import tkinter as tk
        from types import SimpleNamespace
        choice = self.card/"edition.txt"
        choice.write_text("standard\n")
        library = SimpleNamespace(output=self.card, app=self.app, card=self.card, ports=self.ports,
                                  choice=choice, version="1.6.3", existing=lambda edition: self.card/edition,
                                  install=lambda *args: self.fail("Playing an installed edition should skip patching"))
        window = windows.PlayWindow(tk.Tk(), library, True, (640, 480))
        try:
            window.finish_intro()
            window.action("down")
            window.action("accept")
            self.assertTrue(window.play)
            self.assertEqual(choice.read_text().strip(), "dual")
        finally:
            if not window.closed:
                window.busy = False
                window.close()

    def test_card_space_error_keeps_the_player_at_the_edition_menu(self):
        import tkinter as tk
        import time
        from types import SimpleNamespace
        from patch_core import PatchError
        def no_space(*args):
            raise PatchError("More free disk space is needed to rebuild and verify this edition.")
        original = self.original("AM2ARM/1.1.zip")
        library = SimpleNamespace(output=self.card, app=self.app, card=self.card, ports=self.ports,
                                  choice=self.card/"edition.txt", version="1.6.3", install=no_space,
                                  existing=lambda edition: None)
        window = windows.PlayWindow(tk.Tk(), library, True, (640, 480))
        try:
            window.finish_intro()
            window.action("accept")
            deadline = time.monotonic() + 3
            while window.notice is None and time.monotonic() < deadline:
                window.root.update()
                time.sleep(.01)
            self.assertIn("disk space", window.notice.body.get("1.0", "end"))
            window.action("back")
            self.assertIsNone(window.picker)
            self.assertEqual(window.source, original)
        finally:
            window.close()

    def test_upgrade_archives_only_recognized_editions_shortcuts(self):
        path = self.card/"ports/AM2ARM Editions.sh"
        path.parent.mkdir()
        with ZipFile(BASE) as base:
            original = base.read("ports/AM2ARM Editions.sh")
            path.write_bytes(original)
            package = self.card/"Tools/tg5040/AM2ARM Editions.pak"
            package.mkdir(parents=True)
            prior = base.read("Tools/tg5040/AM2ARM.pak/launch.sh").replace(
                b"export AM2ARM_FETCH_DISPLAY=1\n", b"").replace(b'auto "$@"', b'auto --setup "$@"')
            (package/"launch.sh").write_bytes(prior)
        custom = self.card/"roms/ports/AM2ARM Editions.sh"
        custom.parent.mkdir(parents=True)
        custom.write_text("#!/bin/sh\necho custom\n")
        extra = self.card/"Tools/tg5050/AM2ARM Editions.pak"
        extra.mkdir(parents=True)
        (extra/"launch.sh").write_bytes(prior)
        (extra/"notes.txt").write_text("keep")
        lookup.retire_edition_entries(self.card)
        lookup.retire_edition_entries(self.card)
        backup = self.card/"AM2ARM-data/old-menu-entries"
        self.assertFalse(path.exists() or package.exists())
        self.assertEqual((backup/path.relative_to(self.card)).read_bytes(), original)
        self.assertEqual((backup/package.relative_to(self.card)/"launch.sh").read_bytes(), prior)
        self.assertEqual(custom.read_text(), "#!/bin/sh\necho custom\n")
        self.assertEqual((extra/"notes.txt").read_text(), "keep")

    @unittest.skipUnless(os.environ.get("AM2ARM_LAUNCHER_ZIP"), "Set AM2ARM_LAUNCHER_ZIP to check a built launcher.")
    def test_bundled_graphics_include_their_upstream_notices(self):
        expected = {
            "Westonpack.txt": "2500199be1038b3cf9f69b625a3fdc1f79c75f455dac9475f3aec821c5d653cd",
            "gl4es.txt": "69a3049c77abd88658f6ad7cf6a5b6ceb5cf03b80e60f7c4657d90322cfab7bd",
            "PortMaster-New.txt": "9592421b21541ded44fba7fc5c63fb7786b1883cea08d132c26f1abac93b5535",
        }
        with ZipFile(os.environ["AM2ARM_LAUNCHER_ZIP"]) as archive:
            for name, digest in expected.items():
                data = archive.read("am2arm-launcher/AM2ARM/runtime/licenses/" + name)
                self.assertEqual(hashlib.sha256(data).hexdigest(), digest, name)

    def test_offline_graphics_can_sit_beside_original_inside_visible_folder(self):
        import weston_graphics as module
        source = self.card / "AM2ARM" / module.IMAGE
        source.parent.mkdir()
        source.write_bytes(b"fixture")
        with patch.object(module, "cache_image", return_value=True) as cache:
            target = module.locate_graphics(self.card, self.app / "runtime", {})
        self.assertEqual(target, self.card / "AM2ARM-data/runtime/weston-0.2.7.1")
        self.assertEqual(Path(cache.call_args.args[0].name), source)

    @unittest.skipUnless(os.environ.get("AM2ARM_LAUNCHER_ZIP"), "Set AM2ARM_LAUNCHER_ZIP to check a built launcher.")
    def test_inventory_matches_every_packaged_launcher_elf(self):
        root = "am2arm-launcher/AM2ARM/"
        with ZipFile(os.environ["AM2ARM_LAUNCHER_ZIP"]) as archive:
            inventory = archive.read("am2arm-launcher/dependencies/inventory.tsv").decode().splitlines()
            listed = {row["path"]: (int(row["bytes"]), row["sha256"])
                      for row in csv.DictReader(inventory, delimiter="\t") if row["scope"] == "launcher"}
            actual = {}
            for member in archive.infolist():
                if member.is_dir() or not member.filename.startswith(root):
                    continue
                with archive.open(member) as stream:
                    magic = stream.read(4)
                    if magic == b"\x7fELF":
                        actual[member.filename[len(root):]] = (member.file_size, hashlib.sha256(magic + stream.read()).hexdigest())
        self.assertSetEqual(set(actual), set(listed))
        self.assertEqual(actual, listed)

    @unittest.skipUnless(os.environ.get("AM2ARM_LAUNCHER_ZIP"), "Set AM2ARM_LAUNCHER_ZIP to check a built launcher.")
    def test_fresh_card_uses_the_bundled_display_without_a_download(self):
        import build_launcher
        runtime = self.app / "runtime"
        with ZipFile(os.environ["AM2ARM_LAUNCHER_ZIP"]) as archive:
            module = self.packaged_graphics(archive)
            entries = {build_launcher.RUNTIME + "graphics/" + name for name in module.MEMBERS}
            self.assertTrue(entries.issubset(archive.namelist()), "The player download is missing the Brick display libraries.")
            self.assertFalse(any(name.endswith(("weston_pkg_0.2.squashfs", "/AM2R_11.zip")) for name in archive.namelist()))
            for name in entries:
                archive.extract(name, self.card)
        self.original("AM2ARM/AM2R_11.zip")
        with patch("urllib.request.urlopen", side_effect=AssertionError("Network access on a fresh install")):
            chosen = module.prepare_graphics(self.card, runtime, {}, self.fail)
        self.assertEqual(chosen, runtime / "graphics")
        self.assertTrue(module.verified_pair(chosen))
        self.assertFalse((self.card / "AM2ARM-data").exists())

    @unittest.skipUnless(os.environ.get("AM2ARM_LAUNCHER_ZIP"), "Set AM2ARM_LAUNCHER_ZIP to check offline recovery.")
    def test_damaged_graphics_use_local_repair_without_network(self):
        with ZipFile(os.environ["AM2ARM_LAUNCHER_ZIP"]) as archive:
            module = self.packaged_graphics(archive)
            for lib in module.MEMBERS:
                archive.extract("am2arm-launcher/AM2ARM/runtime/graphics/" + lib, self.card)
        graphics = self.app / "runtime/graphics"
        with (graphics / "libcrusty.so").open("r+b") as lib:
            lib.write(b"bad")
        with patch("urllib.request.urlopen", side_effect=AssertionError("Attempted network access")) as request:
            with self.assertRaisesRegex(module.WestonpackRequired, "Re-extract the complete launcher ZIP"):
                module.prepare_graphics(self.card, self.app / "runtime", {}, lambda *args: self.fail("Download offered"))
        request.assert_not_called()
        self.assertFalse((self.card / "AM2ARM-data").exists())

    @unittest.skipUnless(os.environ.get("AM2ARM_LAUNCHER_ZIP"), "Set AM2ARM_LAUNCHER_ZIP to check offline recovery.")
    def test_recovery_does_not_consult_a_separate_port_manager(self):
        with ZipFile(os.environ["AM2ARM_LAUNCHER_ZIP"]) as archive:
            module = self.packaged_graphics(archive)
        manager = self.card / "ports/PortMaster"
        (manager / "libs").mkdir(parents=True)
        (manager / "libs" / module.IMAGE).write_bytes(b"an unrelated runtime")
        with patch.object(module, "cache_image", side_effect=AssertionError("Opened another application's runtime")):
            with self.assertRaisesRegex(module.WestonpackRequired, "Re-extract the complete launcher ZIP"):
                module.locate_graphics(self.card, self.app / "runtime", {"AM2ARM_PORTMASTER_DIR": str(manager)})

    @unittest.skipUnless(os.environ.get("AM2ARM_LAUNCHER_ZIP"), "Set AM2ARM_LAUNCHER_ZIP to check firmware libraries.")
    def test_smart_pro_s_discovers_firmware_graphics_independently(self):
        with ZipFile(os.environ["AM2ARM_LAUNCHER_ZIP"]) as archive:
            path = "am2arm-launcher/AM2ARM/runtime/compat_display.py"
            display = ModuleType("packaged_display")
            exec(compile(archive.read(path), path, "exec"), display.__dict__)
        provided = str(self.card / "firmware-libs")
        with patch.dict(os.environ, {"LD_LIBRARY_PATH": provided}, clear=True):
            folders = display.library_dirs(self.card, "smartpros")
        for directory in (Path("/usr/lib"), self.card/"spruce/flip/lib", self.card/"spruce/brick/sdl2", Path(provided)):
            self.assertIn(directory, folders)
        self.assertNotIn(self.card / "Persistent/portmaster/lib", folders)

    @unittest.skipUnless(os.environ.get("AM2ARM_LAUNCHER_ZIP"), "Set AM2ARM_LAUNCHER_ZIP to check the runtime image.")
    def test_knulli_card_image_matches_loose_runtime_and_excludes_game_data(self):
        with ZipFile(os.environ["AM2ARM_LAUNCHER_ZIP"]) as archive:
            image = "am2arm-launcher/knulli-runtime.squashfs"
            self.assertIn(image, archive.namelist())
            contents = self.card / "contents"
            subprocess.run(["unsquashfs", "-quiet", "-no-progress", "-d", contents,
                            archive.extract(image, self.card)], check=True)
            files = {p.relative_to(contents).as_posix() for p in contents.rglob("*") if p.is_file()}
            expected = {i.filename for i in archive.infolist() if i.filename.startswith("am2arm-launcher/")
                        and not i.is_dir() and "/patch-bundle/" not in i.filename and i.filename != image}
            self.assertEqual(files, expected)
            for name in files:
                self.assertEqual((contents / name).read_bytes(), archive.read(name), name)
            self.assertTrue(os.access(contents / "am2arm-launcher/AM2ARM/runtime/bin/Xvfb", os.X_OK))
            for shortcut in ("ports/AM2ARM.sh", "roms/ports/AM2ARM.sh"):
                self.assertIn(b"knulli-runtime.squashfs", archive.read(shortcut))

    def test_knulli_brick_uses_runner_button_order_for_digital_triggers(self):
        import trimui_device
        pad = self.card / "event3/device"
        (pad / "id").mkdir(parents=True)
        (pad / "capabilities").mkdir()
        (pad / "name").write_text("TRIMUI Brick Controller\n")
        for name, value in zip(("bustype", "vendor", "product", "version"), ("0003", "045e", "028e", "0114")):
            (pad / "id" / name).write_text(value)
        (pad / "capabilities/key").write_text("7fdb000000000003 0 0 c000000000000 0")
        (pad / "capabilities/abs").write_text("30003")
        with patch.object(trimui_device, "knulli_brick_board", return_value=True):
            row = trimui_device.brick_mappings("brick", self.card).split(",")
        self.assertEqual(row[0], "030000005e0400008e02000014010000")
        for field in ("a:b1", "b:b0", "x:b2", "y:b3", "lefttrigger:b6", "righttrigger:b7",
                      "back:b8", "start:b9", "guide:b10", "leftstick:b11", "rightstick:b12", "dpup:h0.1"):
            self.assertIn(field, row)
        self.assertFalse(any(field.startswith(("rightx:", "righty:")) for field in row))
        with patch.object(trimui_device, "knulli_brick_board", return_value=True):
            self.assertEqual(trimui_device.firmware_face_buttons("TRIMUI Brick Controller", {}, {304, 305, 307, 308}),
                             {"a": 305, "b": 304, "x": 307, "y": 308})
        with patch.object(trimui_device, "knulli_brick_board", return_value=False):
            self.assertEqual(trimui_device.firmware_face_buttons("TRIMUI Brick Controller", {}, {304, 305, 307, 308}),
                             {"a": 305, "b": 304, "x": 308, "y": 307})

    def test_unknown_panel_count_defaults_to_standard(self):
        with patch.object(lookup, "Path", side_effect=lambda path: self.card / path.lstrip("/")), patch.dict(os.environ, {}, clear=True):
            self.assertTrue(lookup.single_screen("ports"))

    def test_stock_rg_ds_edition_detection_with_generic_device_tree(self):
        device_tree = self.card / "proc/device-tree/model"
        device_tree.parent.mkdir(parents=True)
        device_tree.write_bytes(b"Rockchip RK3568 DEEP LP3 V10 Board\0")
        vendor_model = self.card / "sys/class/anbernic_misc/model"
        vendor_model.parent.mkdir(parents=True)
        with patch.object(lookup, "Path", side_effect=lambda path: self.card / path.lstrip("/")):
            self.assertFalse(lookup.is_rg_ds(lookup.board_model()))
            vendor_model.write_bytes(b"rg35xx\n")
            self.assertFalse(lookup.is_rg_ds(lookup.board_model()))
            vendor_model.write_bytes(b"rgds\n")
            self.assertTrue(lookup.is_rg_ds(lookup.board_model()))
            self.assertFalse(lookup.single_screen("ports"))
            self.assertTrue(lookup.single_screen("direct"))

    def test_unlisted_board_detects_one_or_two_live_outputs(self):
        drm = self.card/"sys/class/drm"
        for connector in ("card0-DSI-1", "card0-DSI-2"):
            status = drm/connector/"status"
            status.parent.mkdir(parents=True)
            status.write_text("connected\n")
        with patch.object(lookup, "Path", side_effect=lambda path: self.card / path.lstrip("/")), \
                patch.dict(os.environ, {}, clear=True):
            self.assertFalse(lookup.single_screen("ports"))
            (drm/"card0-DSI-2/status").write_text("disconnected\n")
            self.assertTrue(lookup.single_screen("ports"))

    @unittest.skipUnless(os.environ.get("AM2ARM_LAUNCHER_ZIP"), "Set AM2ARM_LAUNCHER_ZIP for direct display checks.")
    def test_direct_display_can_install_dual_without_starting_one_output_game(self):
        import json
        module = ModuleType("packaged_session")
        module.__file__ = str(released/"nextui_session.py")
        with ZipFile(os.environ["AM2ARM_LAUNCHER_ZIP"]) as archive:
            code = archive.read("am2arm-launcher/AM2ARM/runtime/nextui_session.py")
        exec(compile(code, module.__file__, "exec"), module.__dict__)
        game = self.card/"game"
        game.mkdir()
        for edition, game_route in (("standard", True), ("dual-screen", False)):
            (game/"edition.json").write_text(json.dumps({"edition": edition}))
            with self.subTest(edition=edition), patch.dict(os.environ, {"AM2ARM_PLAY_DIR": str(game)}, clear=True), \
                    patch.object(module, "report"), patch.object(module, "display_options", side_effect=StopIteration) as probe:
                with self.assertRaises(StopIteration):
                    module.run("game", "brick")
                _, environment, wants_game_renderer = probe.call_args.args
                self.assertEqual(wants_game_renderer, game_route)
                self.assertEqual(environment.get("AM2ARM_DISPLAY_NOTICE"), None if game_route else "dual-screen")

    @unittest.skipUnless(os.environ.get("AM2ARM_LAUNCHER_ZIP"), "Set AM2ARM_LAUNCHER_ZIP for runner checks.")
    def test_smart_pro_s_game_receives_the_firmware_kms_display(self):
        import json
        from contextlib import ExitStack
        from compat_display import identify, video_drivers
        module = ModuleType("packaged_session")
        module.__file__ = str(released/"nextui_session.py")
        with ZipFile(os.environ["AM2ARM_LAUNCHER_ZIP"]) as archive:
            code = archive.read("am2arm-launcher/AM2ARM/runtime/nextui_session.py")
            self.assertIn("am2arm-launcher/AM2ARM/runtime/kms/libGL.so.1", archive.namelist())
        exec(compile(code, module.__file__, "exec"), module.__dict__)
        device = identify("sun55iw3", "", "SmartProS", "Buildroot")
        firmware_sdl = Path("/usr/lib/libSDL2-2.0.so.0.3200.6")
        egl, gles = Path("/usr/lib/libEGL.so.1.4.0"), Path("/usr/lib/libGLESv2.so.2.1.0")
        driver, = video_drivers(device, ["KMSDRM", "offscreen", "dummy", "evdev"])
        game = self.card/"game"
        game.mkdir()
        metadata = {"edition": "standard", "game_label": "AM2ARM Standard"}
        (game/"edition.json").write_text(json.dumps(metadata))
        class ReachedRunner(Exception):
            pass
        def start(command, environment, log, cwd=None):
            if str(game/"data/runner") not in command:
                return None
            self.assertEqual(command[-3:], [str(game/"data/runner"), "-game", str(game/"data/game.unx")])
            self.assertIn(str(module.RUNTIME/"kms"), command[2].split(":"))
            self.assertEqual(environment["AM2ARM_KMS_SIZE"], "1280x720")
            self.assertEqual(environment["AM2ARM_STOCK_DISPLAY"], "1")
            self.assertEqual(environment["AM2ARM_FIRMWARE_SDL"], str(firmware_sdl))
            self.assertEqual(environment["SDL_VIDEO_EGL_DRIVER"], str(egl))
            self.assertEqual(environment["SDL_VIDEO_GL_DRIVER"], str(gles))
            self.assertEqual(environment["EGL_PLATFORM"], "gbm")
            self.assertEqual(environment["LIBGL_DEEPBIND"], "0")
            self.assertNotIn("WAYLAND_DISPLAY", environment)
            raise ReachedRunner
        with ExitStack() as stack:
            stack.enter_context(patch.dict(os.environ, {"AM2ARM_PLAY_DIR": str(game),
                "AM2ARM_FRONTEND": "spruce", "AM2ARM_DEVICE_PROFILE": device}, clear=True))
            stack.enter_context(patch.object(module, "report"))
            stack.enter_context(patch.object(module, "wait_ready"))
            stack.enter_context(patch.object(module, "start", start))
            stack.enter_context(patch.object(module, "game_options", return_value=(self.card/"saves", metadata)))
            stack.enter_context(patch.object(module, "display_options", return_value=iter([(firmware_sdl, driver, egl, gles)])))
            with self.assertRaises(ReachedRunner):
                module.run("game", device)

    def test_knulli_brick_uses_the_board_file_for_a_generic_a133(self):
        import trimui_device
        files = {
            "/proc/device-tree/model": "sun50iw10",
            "/etc/os-release": 'NAME=Batocera.linux\nOS_NAME="knulli"',
            "/boot/boot/knulli.board": "trimui-brick",
        }
        with patch.dict(os.environ, {"AM2ARM_FRONTEND": "ports"}, clear=True), \
                patch.object(trimui_device, "read", side_effect=lambda path: files.get(path, "")):
            try:
                device = trimui_device.current_device()
            except RuntimeError as error:
                self.fail(f"KNULLI's Brick board marker should identify the panel: {error}")
            self.assertEqual((device, trimui_device.display_size(device)), ("brick", (1024, 768)))
            for path, value in (("/boot/boot/knulli.board", "trimui-smart-pro"),
                                ("/boot/boot/knulli.board", ""),
                                ("/etc/os-release", "NAME=Batocera.linux"),
                                ("/proc/device-tree/model", "sun55iw3"),
                                ("/proc/cpuinfo", "tg4040")):
                with self.subTest(path=path, value=value), patch.dict(files, {path: value}):
                    with self.assertRaises(RuntimeError):
                        trimui_device.current_device()

    def test_stock_firmware_identifiers_require_the_matching_handheld(self):
        import trimui_device
        cases = (
            ("BatleXP G-G-G-G350!", "ID=debian", "G350", "", "g350"),
            ("Different RK3326", "ID=debian", "G350", "", None),
            ("sun50iw10", "ID=muos", "", "tui-brick", "brick"),
            ("sun50iw10", "ID=buildroot", "", "tui-brick", "brick"),
            ("sun50iw10", "ID=muos", "", "tui-brick-pro", None),
            ("sun50iw10", "ID=muos", "", "", None),
        )
        for model, release, ark, muos, expected in cases:
            files = {"/etc/os-release":release, "/proc/device-tree/model":model,
                     "/home/ark/.config/.DEVICE":ark, "/opt/muos/device/config/board/name":muos}
            with self.subTest(model=model, muos=muos), patch.dict(os.environ, {}, clear=True), \
                    patch.object(trimui_device, "read", lambda p: files.get(p, "")):
                if expected is None:
                    with self.assertRaises(RuntimeError):
                        trimui_device.current_device()
                else:
                    self.assertEqual(trimui_device.current_device(), expected)
                    self.assertEqual(trimui_device.firmware_display_loader(expected),
                                     Path("/lib/ld-linux-aarch64.so.1" if expected == "brick" else "/usr/lib/ld-linux-aarch64.so.1"))

    def test_muos_game_and_menu_honor_firmware_face_layout(self):
        import trimui_device
        keys = {114,115,256,257,304,305,307,308,310,311,312,313,314,315,316,317,318}
        pad = self.card/"event0/device"
        (pad/"capabilities").mkdir(parents=True)
        (pad/"name").write_text("muOS-Keys\n")
        bits = sum(1 << key for key in keys)
        (pad/"capabilities/key").write_text(" ".join(f"{bits>>i & ((1<<64)-1):x}" for i in (256,192,128,64,0)))
        guid = "060000006d750000020000006f730000,muOS-Keys,"
        retro = guid + "x:b6,a:b5,b:b4,y:b7,back:b12,start:b13,dpup:h0.1,"
        modern = guid + "x:b7,a:b4,b:b5,y:b6,back:b12,start:b13,dpup:h0.1,"
        files = {"/etc/os-release":"ID=muos", "/opt/muos/device/config/board/name":"tui-brick",
                 "/proc/device-tree/model":"sun50iw10", "/opt/muos/device/config/board/sdl_map":retro}
        for config, runner, faces in (
            ("", "x:b2,a:b1,b:b0,y:b3,back:b8,start:b9,dpup:h0.1,", {"a":305,"b":304,"x":307,"y":308}),
            (modern, "x:b3,a:b0,b:b1,y:b2,back:b8,start:b9,dpup:h0.1,", {"a":304,"b":305,"x":308,"y":307}),
        ):
            with self.subTest(config=config), patch.object(trimui_device, "read", lambda p: files.get(p, "")), \
                    patch.dict(os.environ, {"SDL_GAMECONTROLLERCONFIG":config}):
                self.assertEqual(trimui_device.brick_mappings(input_root=self.card), guid+runner)
                self.assertEqual(trimui_device.firmware_face_buttons("muOS-Keys", (), keys), faces)

    def test_darkos_mapping_uses_the_g350_row_from_its_firmware(self):
        import trimui_device
        db = self.card/"gamecontrollerdb.txt"
        expected = "190000004b4800000011000000010000,GO-Super Gamepad,a:b1,b:b0,x:b2,y:b3,platform:Linux,"
        db.write_text("0,Some other pad,a:b0,platform:Linux,\n" + expected + "\n")
        files = {"/etc/os-release":"ID=debian", "/proc/device-tree/model":"BatleXP G-G-G-G350!",
                 "/home/ark/.config/.DEVICE":"G350"}
        with patch.object(trimui_device, "read", lambda p: files.get(p, "")):
            self.assertEqual(trimui_device.panel_mapping("g350", darkos_database=db), expected)

    def test_private_audio_applies_only_to_the_two_matching_firmwares(self):
        import trimui_device
        markers = {"/home/ark/.config/.DEVICE":"G350", "/opt/muos/device/config/board/name":"tui-brick"}
        for model, release, device, entry in (
            ("BatleXP G-G-G-G350!", "ID=debian", "g350", "prepare_darkos_audio"),
            ("sun50iw10", "ID=muos", "brick", "prepare_muos_audio"),
            ("Anbernic RG35", "NAME=AmberELEC", "g350", None),
            ("sun50iw10", "NAME=NextUI", "brick", None),
        ):
            files = dict(markers, **{"/etc/os-release":release, "/proc/device-tree/model":model})
            with self.subTest(device=device, release=release), patch.object(trimui_device, "read", lambda p: files.get(p, "")):
                handler = trimui_device.firmware_audio_session(device)
                self.assertEqual(handler.__name__ if handler else None, entry)

    def test_explicit_wayland_handoff_from_tools(self):
        env = {"XDG_RUNTIME_DIR": "/run/test", "WAYLAND_DISPLAY": "wayland-4"}
        probed = []
        def session(given):
            probed.append(given["WAYLAND_DISPLAY"])
            return dict(given)
        route, _ = routes.resolve_display("nextui", env, session=session, device=lambda: "brick", ports_ready=lambda env: True)
        self.assertEqual((route, probed), ("ports", ["wayland-4"]))

    def test_firmware_display_libraries_use_the_matching_runtime(self):
        import nextui_session
        import trimui_device
        files = {"/etc/os-release": 'OS_NAME="knulli"', "/boot/boot/knulli.board": "trimui-brick",
                 "/proc/device-tree/model": "sun50iw10"}
        core = nextui_session.RUNTIME / "core"
        for profile, release, loader in (
            ("brick", 'OS_NAME="knulli"', Path("/lib/ld-linux-aarch64.so.1")),
            ("brick", "NAME=NextUI", core / "ld-linux-aarch64.so.1"),
            ("g350", "NAME=AmberELEC", Path("/usr/lib/ld-linux-aarch64.so.1")),
        ):
            with self.subTest(profile=profile, release=release), patch.dict(files, {"/etc/os-release": release}), \
                    patch.object(trimui_device, "read", side_effect=lambda path: files.get(path, "")), \
                    patch.dict(os.environ, {"AM2ARM_DEVICE_PROFILE": profile}, clear=True):
                args = nextui_session.command("/runner", extra=(Path("/usr/lib"),))
                self.assertEqual(args[0], str(loader))
                self.assertEqual(str(core) in args[2].split(":"), loader.parent == core)

    def test_wayland_without_game_launcher_dependencies_uses_direct(self):
        env = {"XDG_RUNTIME_DIR": "/run/test", "WAYLAND_DISPLAY": "wayland-4"}
        route, _ = routes.resolve_display("nextui", env, session=dict, device=lambda: "brick", ports_ready=lambda env: False)
        self.assertEqual(route, "direct")

    def test_ports_requires_game_launcher_dependencies_too(self):
        env = {"XDG_RUNTIME_DIR": "/run/test", "WAYLAND_DISPLAY": "wayland-0"}
        route, _ = routes.resolve_display("ports", env, session=dict, device=lambda: "g350", ports_ready=lambda env: False)
        self.assertEqual(route, "direct")

    def test_direct_entry_with_no_declared_session_keeps_vendor_route(self):
        def unexpected(env):
            self.fail("An unrelated desktop must not take over the handheld menu")
        name, env = routes.resolve_display("nextui", {}, session=unexpected, device=lambda: "brick")
        self.assertEqual((name, env["AM2ARM_DEVICE_PROFILE"]), ("direct", "brick"))

    def test_stale_declared_session_does_not_adopt_another_session_from_tools(self):
        env = {"WAYLAND_DISPLAY": "wayland-4", "XDG_RUNTIME_DIR": "/run/test"}
        other = lambda e: dict(e, WAYLAND_DISPLAY="wayland-3")
        name, _ = routes.resolve_display("nextui", env, session=other, device=lambda: "brick", ports_ready=lambda env: True)
        self.assertEqual(name, "direct")

    def test_ports_preserves_ambiguous_session_error(self):
        def ambiguous(env):
            raise routes.AmbiguousWaylandSession("multiple")
        with self.assertRaises(routes.AmbiguousWaylandSession):
            routes.resolve_display("ports", {}, session=ambiguous, device=lambda: "g350")

    def test_controller_can_accept_dual_or_switch_to_standard(self):
        import tkinter as tk
        from types import SimpleNamespace
        from handheld_gui import HandheldWindow
        library = SimpleNamespace(output=self.card, app=self.app, card=self.card, ports=self.ports,
                                  choice=self.card/"edition.txt", version="1.6.3")
        library.install = lambda *args: self.fail("A highlighted edition must wait for confirmation")
        library.existing = lambda edition: None
        root = tk.Tk()
        window = windows.PlayWindow(root, library, False, (640, 480))
        self.addCleanup(window.close)
        window.finish_intro()
        self.assertEqual(root.title(), "AM2ARM Launcher")
        self.assertIn("LAUNCHER", window.canvas.itemcget(window.subtitle, "text"))
        self.assertEqual((window.edition, window.focus_index), ("dual", 1))
        window.action("up")
        self.assertEqual(window.focus_index, 0)
        with patch.object(HandheldWindow, "begin") as begin:
            window.action("accept")
            self.assertEqual(window.edition, "standard")
            begin.assert_called_once()

    def test_one_display_offers_both_editions_and_waits_for_accept(self):
        import tkinter as tk
        from types import SimpleNamespace
        from handheld_gui import HandheldWindow
        library = SimpleNamespace(output=self.card, app=self.app, card=self.card, ports=self.ports,
                                  choice=self.card/"edition.txt", version="1.6.3",
                                  install=lambda *args: self.fail("Unconfirmed install"),
                                  existing=lambda edition: None)
        for backend in ("ports", "direct"):
            with self.subTest(backend=backend), patch.dict(os.environ, {"AM2ARM_DISPLAY_PATH": backend}), \
                    patch.object(HandheldWindow, "begin") as begin:
                root = tk.Tk()
                window = windows.PlayWindow(root, library, True, (640, 480))
                try:
                    window.finish_intro()
                    begin.assert_not_called()
                    self.assertTrue(window.standard.visible and window.dual.visible)
                    self.assertEqual((window.edition, window.focus_index), ("standard", 0))
                    window.action("down")
                    self.assertEqual(window.focus_index, 1)
                    begin.assert_not_called()
                    window.action("accept")
                    self.assertEqual(window.edition, "dual")
                    begin.assert_called_once()
                finally:
                    window.close()

    def test_fresh_two_output_device_and_explicit_choice(self):
        import tkinter as tk
        from types import SimpleNamespace
        library = SimpleNamespace(output=self.card, app=self.app, card=self.card, ports=self.ports,
                                  choice=self.card/"edition.txt", version="1.6.3",
                                  existing=lambda edition: None,
                                  install=lambda *args: self.fail("Unconfirmed install"))
        for single, saved, expected in ((False, None, "dual"), (False, "standard", "standard"),
                                         (True, "dual", "dual")):
            with self.subTest(single=single, saved=saved):
                if saved:
                    library.choice.write_text(saved)
                root = tk.Tk()
                window = windows.PlayWindow(root, library, single, (640, 480))
                try:
                    self.assertEqual(window.edition, expected)
                finally:
                    window.close()

    def test_resume_honors_saved_dual_when_one_display_is_detected(self):
        from types import SimpleNamespace
        library = SimpleNamespace(choice=self.card/"edition.txt", output=self.card)
        library.choice.write_text("dual\n")
        library.existing = lambda edition: self.card/edition
        library.selected = lambda single: lookup.Library.selected(library, single)
        output = io.StringIO()
        with patch.object(lookup.Library, "from_environment", return_value=library), \
                patch.object(sys, "argv", ["first_run.py", "1"]), redirect_stdout(output):
            runpy.run_path(str(PROTOTYPE/"first_run.py"), run_name="__main__")
        self.assertEqual(output.getvalue().strip(), str(self.card/"dual"))

    def test_existing_game_without_an_edition_choice_opens_the_picker(self):
        from types import SimpleNamespace
        library = SimpleNamespace(choice=self.card/"edition.txt", output=self.card)
        library.existing = lambda edition: self.card/"standard" if edition == "standard" else None
        library.selected = lambda single: lookup.Library.selected(library, single)
        for choice in (None, "dual", "unrecognized"):
            with self.subTest(choice=choice):
                if choice:
                    library.choice.write_text(choice)
                with patch.object(lookup.Library, "from_environment", return_value=library), \
                        patch.object(sys, "argv", ["first_run.py", "1"]), redirect_stdout(io.StringIO()) as out:
                    runpy.run_path(str(PROTOTYPE/"first_run.py"), run_name="__main__")
                self.assertEqual(out.getvalue(), "")

    def test_labels_report_actual_installations_on_each_display_path(self):
        import tkinter as tk
        from types import SimpleNamespace
        for backend, games, expected in (
            ("direct", (), ("INSTALL STANDARD", "INSTALL DUAL SCREEN")),
            ("ports", (), ("INSTALL STANDARD", "INSTALL DUAL SCREEN")),
            ("direct", ("standard", "dual"), ("PLAY STANDARD", "DUAL SCREEN INSTALLED")),
            ("ports", ("dual",), ("INSTALL STANDARD", "PLAY DUAL SCREEN")),
        ):
            with self.subTest(backend=backend, games=games), patch.dict(os.environ, {"AM2ARM_DISPLAY_PATH": backend}):
                library = SimpleNamespace(output=self.card, app=self.app, card=self.card, ports=self.ports,
                                          choice=self.card/"edition.txt", version="1.6.3",
                                          existing=lambda edition: self.card/edition if edition in games else None)
                window = windows.PlayWindow(tk.Tk(), library, True, (640, 480))
                try:
                    window.finish_intro()
                    self.assertEqual(tuple(window.canvas.itemcget(b.text_item, "text")
                                           for b in (window.standard, window.dual)), expected)
                finally:
                    window.close()

    def test_install_only_dual_keeps_standard_as_the_game_to_resume(self):
        import tkinter as tk
        from types import SimpleNamespace
        import time
        self.original("AM2ARM/source.zip")
        choice = self.card/"edition.txt"
        choice.write_text("standard\n")
        games = {"standard"}
        def install(source, output, edition, progress):
            games.add(edition)
            choice.write_text(edition+"\n")  # The released installation module records an install.
            return self.card/edition, "verified"
        library = SimpleNamespace(output=self.card, app=self.app, card=self.card, ports=self.ports, choice=choice,
                                  version="1.6.3", existing=lambda e: self.card/e if e in games else None, install=install)
        with patch.dict(os.environ, {"AM2ARM_DISPLAY_PATH": "direct"}):
            window = windows.PlayWindow(tk.Tk(), library, True, (640, 480))
            self.addCleanup(window.close)
            window.finish_intro()
            window.action("down")
            window.action("accept")
            until = time.monotonic() + 4
            while not (window.notice or window.closed) and time.monotonic() < until:
                window.root.update()
                time.sleep(.01)
            self.assertFalse(window.closed)
            self.assertIsNotNone(window.notice)
            self.assertEqual(choice.read_text().strip(), "standard")
            window.action("accept")
            self.assertEqual(window.canvas.itemcget(window.dual.text_item, "text"), "DUAL SCREEN INSTALLED")
            self.assertEqual(window.edition, "standard")

    def test_relaunch_skips_picker_but_explicit_setup_and_missing_game_open_it(self):
        rt = self.app/"runtime"
        loader = rt/"core/ld-linux-aarch64.so.1"
        loader.parent.mkdir(parents=True)
        target = self.card/"game"
        target.mkdir()
        gate = self.app/"patcher/launch.sh"
        gate.parent.mkdir()
        actions = self.card/"events"
        gate.write_text('echo menu >> "$EVENTS"\n')
        (target/"launch.sh").write_text('echo game >> "$EVENTS"\n')
        loader.write_text('''#!/bin/sh
case "${4##*/}:$5" in
    first_run.py:screens) echo 1 ;;
    first_run.py:resume) [ "$VALID" != yes ] || echo "$GAME" ;;
    first_run.py:*) echo "$GAME" ;;
    nextui_session.py:*) echo "$5" | sed 's/patcher/menu/' >> "$EVENTS" ;;
esac
''')
        loader.chmod(0o755)
        for backend in ("ports", "direct"):
            for valid, args, expected in (("yes", [], ["game"]), ("yes", ["--setup"], ["menu", "game"]),
                                          ("no", [], ["menu", "game"])):
                with self.subTest(backend=backend, valid=valid, args=args):
                    actions.write_text("")
                    env = dict(os.environ, AM2ARM_RUNTIME_DIR=str(rt), SDCARD_PATH=str(self.card),
                               AM2ARM_FRONTEND="stock", AM2ARM_DISPLAY_PATH=backend, EVENTS=str(actions),
                               GAME=str(target), VALID=valid, AM2ARM_PORTS_DIR=str(self.ports))
                    subprocess.run(["sh", PROTOTYPE/"session.sh", "auto", *args], env=env,
                                   capture_output=True, check=True)
                    self.assertEqual(actions.read_text().splitlines(), expected)

    def test_resume_rejects_install_only_dual_and_honors_held_control(self):
        from types import SimpleNamespace
        library = SimpleNamespace(choice=self.card/"edition.txt", existing=lambda e: self.card/e)
        library.choice.write_text("dual\n")
        self.assertIsNone(lookup.resume_game(library, "direct", lambda: False))
        self.assertEqual(lookup.resume_game(library, "ports", lambda: False), self.card/"dual")
        library.choice.write_text("standard\n")
        self.assertEqual(lookup.resume_game(library, "direct", lambda: False), self.card/"standard")
        self.assertIsNone(lookup.resume_game(library, "ports", lambda: True))
        library.existing = lambda e: None
        self.assertIsNone(lookup.resume_game(library, "ports", lambda: False))

    def test_dpad_menu_override_reads_button_or_hat_without_waiting_for_a_new_press(self):
        import struct
        sysfs, dev = self.card/"sys", self.card/"dev"
        cap = sysfs/"event0/device/capabilities"
        cap.mkdir(parents=True)
        dev.mkdir()
        (dev/"event0").touch()
        def bitmap(codes):
            # The test targets the 64-bit native host and ARM64 handheld ABI.
            bits = sum(1 << n for n in codes)
            return " ".join(f"{(bits >> pos) & ((1 << 64)-1):x}"
                            for pos in reversed(range(0, max(1, bits.bit_length()), 64)))
        for keys, axes, pressed, y, expected in (
            ([304,544,545,546,547], [], [544], 0, True),
            ([304,544,545,546,547], [], [545], 0, False),
            ([304], [16,17], [], -1, True), ([304], [16,17], [], 1, False),
            ([103], [], [103], 0, False),
        ):
            with self.subTest(keys=keys, y=y, held=pressed):
                (cap/"key").write_text(bitmap(keys))
                (cap/"abs").write_text(bitmap(axes))
                def ioctl(pad, request, data):
                    if request == 0x80604518:
                        return sum(1 << n for n in pressed).to_bytes(96, "little")
                    self.assertEqual(request, 0x80184551)
                    return struct.pack("=6i", y, -1, 1, 0, 0, 0)
                with patch.object(lookup.fcntl, "ioctl", side_effect=ioctl):
                    self.assertEqual(lookup.dpad_up_held(sysfs, dev), expected)

    @unittest.skipUnless(os.environ.get("AM2ARM_LAUNCHER_ZIP"), "Set AM2ARM_LAUNCHER_ZIP for packaged entries.")
    def test_only_one_am2arm_entry_per_firmware_menu(self):
        from pathlib import PurePosixPath
        folders = {"ports", "roms/ports", "App", "Apps", "Tools/my355", "Tools/tg5040", "Tools/tg5050"}
        with ZipFile(os.environ["AM2ARM_LAUNCHER_ZIP"]) as archive:
            for folder in folders:
                with self.subTest(folder=folder):
                    children = {PurePosixPath(n).relative_to(folder).parts[0] for n in archive.namelist()
                                if n.startswith(folder+"/") and not n.endswith("/")}
                    expected = "AM2ARM.sh" if folder.endswith("ports") else (
                        "AM2ARM.pak" if folder.startswith("Tools/") else "AM2ARM")
                    self.assertEqual(children, {expected})


if __name__ == "__main__":
    unittest.main()
