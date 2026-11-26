"""Exercise the shipped font, Ports metadata and default selection artwork."""
import json
import os
from pathlib import Path
from tempfile import TemporaryDirectory
from types import SimpleNamespace
from unittest.mock import Mock, patch
from zipfile import ZipFile


class LauncherArtChecks:
    def ports_thumbnail(self):
        from build_launcher import ports_thumbnail
        self.ports.mkdir(parents=True)
        (self.ports/"AM2ARM.sh").touch()
        image = self.app/"patcher/assets/ports-thumbnail.png"
        image.parent.mkdir(parents=True)
        with ZipFile(os.environ["AM2ARM_BASE_ZIP"]) as package:
            image.write_bytes(ports_thumbnail(package))
        return image

    def test_amberelec_migrates_the_verified_portmaster_image_in_place(self):
        from ports_art import prepare_ports_art
        from PIL import Image
        previous = Path(os.environ["AM2ARM_BASE_ZIP"]).with_name("am2arm.zip")
        if not previous.is_file():
            self.skipTest("The companion 1.6.3 PortMaster ZIP supplies the original artwork.")
        new = self.ports_thumbnail()
        with Image.open(new) as image:
            self.assertEqual(image.size, (480, 360))
        old = self.ports/"am2arm/screenshot.png"
        old.parent.mkdir()
        with ZipFile(previous) as archive:
            old.write_bytes(archive.read("am2arm/screenshot.png"))
        markup = (b"<gameList><game><path>./PortMaster.sh</path><favorite>true</favorite></game>"
                  b"<game><path>./AM2ARM.sh</path><image>./am2arm/screenshot.png</image>"
                  b"<playcount>3</playcount></game></gameList>")
        gamelist = self.ports/"gamelist.xml"
        gamelist.write_bytes(markup)
        with patch("ports_art.HTTPConnection") as service:
            prepare_ports_art(self.ports, self.app)
            self.assertEqual(old.read_bytes(), new.read_bytes())
            timestamp = old.stat().st_mtime_ns
            prepare_ports_art(self.ports, self.app)
            self.assertEqual(old.stat().st_mtime_ns, timestamp)
            old.write_bytes(b"player artwork")
            prepare_ports_art(self.ports, self.app)
            self.assertEqual(old.read_bytes(), b"player artwork")
            service.assert_not_called()
        self.assertEqual(gamelist.read_bytes(), markup)

    def test_empty_running_ports_entry_registers_only_its_own_image(self):
        from ports_art import prepare_ports_art
        new = self.ports_thumbnail()
        game = {"systemName": "ports", "id": "0"*32, "path": str(self.ports/"AM2ARM.sh")}
        with patch("ports_art.HTTPConnection") as service:
            connection = service.return_value
            reply = Mock(status=200)
            reply.read.return_value = json.dumps(game).encode()
            connection.getresponse.return_value = reply
            prepare_ports_art(self.ports, self.app)
            service.assert_called_once()
            self.assertEqual(service.call_args.args[:2], ("127.0.0.1", 1234))
            calls = connection.request.call_args_list
            self.assertEqual(calls[0].args[:2], ("GET", "/runningGame"))
            self.assertEqual(calls[1].args[:2], ("POST", "/systems/ports/games/" + "0"*32 + "/media/image"))
            self.assertEqual(calls[1].kwargs["body"], new.read_bytes())
            self.assertEqual(calls[1].kwargs["headers"]["Content-Type"], "image/png")
            for custom in (dict(game, image="/player-cover"), dict(game, thumbnail="/player-thumb"),
                           dict(game, path=str(self.ports/"Other.sh"))):
                with self.subTest(metadata=custom):
                    connection.reset_mock()
                    reply.read.return_value = json.dumps(custom).encode()
                    prepare_ports_art(self.ports, self.app)
                    self.assertEqual([c.args[0] for c in connection.request.call_args_list], ["GET"])
            connection.reset_mock()
            reply.read.return_value = json.dumps(game).encode()
            local = self.ports/"images/AM2ARM-image.png"
            local.parent.mkdir()
            local.write_bytes(b"custom local artwork")
            prepare_ports_art(self.ports, self.app)
            self.assertNotIn("POST", [c.args[0] for c in connection.request.call_args_list])
            self.assertEqual(local.read_bytes(), b"custom local artwork")
        self.assertFalse((self.ports/"gamelist.xml").exists())

    def test_offline_ports_catalog_keeps_other_games_and_player_metadata(self):
        from ports_art import prepare_ports_art
        from xml.etree import ElementTree
        thumbnail = self.ports_thumbnail()
        path = self.ports/"gamelist.xml"
        other = b"<game data='keep'><path>./Other.sh</path><image>./own.jpg</image></game>"
        stats = b"<rating>0.7</rating><!-- keep --><playcount>4</playcount>"
        original = b"<?xml version='1.0'?><gameList>\n" + other + b"\n<game><path>./AM2ARM.sh</path>" + stats
        original += b"<image /></game></gameList><!-- trailing note -->"
        with patch("ports_art.HTTPConnection", side_effect=ConnectionRefusedError):
            for initial in (None, b"<gameList />", b"<gameList>"+other+b"</gameList>", original):
                with self.subTest(initial=initial), TemporaryDirectory() as area:
                    ports = Path(area)
                    (ports/"AM2ARM.sh").touch()
                    catalog = ports/path.name
                    if initial is not None:
                        catalog.write_bytes(initial)
                    prepare_ports_art(ports, self.app)
                    written = catalog.read_bytes()
                    node = ElementTree.fromstring(written).find("game[path='./AM2ARM.sh']")
                    self.assertEqual(len(node.findall("image")), 1)
                    self.assertEqual(node.findtext("image"), "./images/AM2ARM-image.png")
                    self.assertEqual((ports/node.findtext("image")).read_bytes(), thumbnail.read_bytes())
                    if initial and other in initial:
                        self.assertIn(other, written)
                    if initial == original:
                        self.assertIn(stats, written)
                        self.assertTrue(written.endswith(b"</gameList><!-- trailing note -->"))
                    if initial is not None:
                        self.assertEqual((ports/"gamelist.xml.am2arm.bak").read_bytes(), initial)
                    timestamp = catalog.stat().st_mtime_ns
                    prepare_ports_art(ports, self.app)
                    self.assertEqual(catalog.stat().st_mtime_ns, timestamp)

    def test_external_ports_catalog_keeps_its_priority(self):
        from ports_art import prepare_ports_art
        thumbnail = self.ports_thumbnail()
        external = self.card/"firmware/gamelists/ports/gamelist.xml"
        external.parent.mkdir(parents=True)
        external.write_bytes(b"<gameList><game><path>Other.sh</path><favorite>true</favorite></game></gameList>")
        original = external.read_bytes()
        with patch("ports_art.OTHER_CATALOGS", (external,)), patch("ports_art.HTTPConnection", side_effect=OSError):
            prepare_ports_art(self.ports, self.app)
        self.assertFalse((self.ports/"gamelist.xml").exists())
        self.assertEqual(external.read_bytes(), original)
        self.assertEqual((self.ports/"images/AM2ARM-image.png").read_bytes(), thumbnail.read_bytes())

    def test_focus_background_centers_the_visible_capitals(self):
        from tkinter import Tk
        from PIL import ImageGrab
        from first_run_gui import PlayWindow

        library = SimpleNamespace(output=self.card, app=self.app, card=self.card, ports=self.ports,
                                  choice=self.card/"choice", version="1.6.3", existing=lambda _: None)
        with patch.dict(os.environ, {"AM2ARM_DISPLAY_PATH": "direct", "AM2R_PATCHER_SILENT": "1"}):
            for size in ((640, 480), (1024, 768), (1280, 720)):
                root = Tk()
                root.overrideredirect(True)
                window = PlayWindow(root, library, True, size)
                try:
                    # The standard test X server can have a smaller desktop than the handheld.
                    screen_width, screen_height = root.winfo_screenwidth(), root.winfo_screenheight()
                    w, h = size
                    root.geometry(f"{w}x{h}+{(screen_width-w)//2}+{(screen_height-h)//2}")
                    root.update()
                    window.finish_intro()
                    for index, button in enumerate(window.buttons):
                        with self.subTest(panel=size, label=button.text):
                            if index:
                                window.action("down")
                            root.update()
                            self.assertEqual(root.tk.call("font", "actual", button.font, "-family"),
                                             "Extended Acknowledge TT BRK")
                            x, y, width, height = button.bounds
                            x += window.canvas.winfo_rootx()
                            y += window.canvas.winfo_rooty()
                            area = (max(0, x), y, min(screen_width, x+width), y+height)
                            selected = ImageGrab.grab(area, xdisplay=root.winfo_screen())
                            self.assertEqual(selected.getpixel((0, 0)), (75, 75, 75))
                            self.assertEqual(selected.getpixel((0, height-1)), (75, 75, 75))
                            ink = selected.convert("L").point(lambda value: 255 if value >= 160 else 0).getbbox()
                            self.assertIsNotNone(ink)
                            self.assertAlmostEqual(ink[1], height-ink[3], delta=1)
                finally:
                    window.close()
