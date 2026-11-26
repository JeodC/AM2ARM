"""Maintain the AM2ARM Ports image without replacing an EmulationStation gamelist."""
from contextlib import closing
import hashlib
from http.client import HTTPConnection, HTTPException
import json
import os
from pathlib import Path
import re
from tempfile import NamedTemporaryFile
from xml.etree import ElementTree
from xml.parsers import expat


# 1.6.3 PortMaster's am2arm/screenshot.png.
OLD_SIZE = 175180
OLD_SHA256 = "92b6f417ae638ec4587123eeaf10e6b855c631521a854c697c38dc2e45c6afe3"
DEFAULT_IMAGE = "images/AM2ARM-image.png"
OTHER_CATALOGS = tuple(folder/"gamelists/ports/gamelist.xml" for folder in (
    Path("/storage/.config/emulationstation"), Path("/home/ark/.emulationstation"),
    Path.home()/".emulationstation", Path("/etc/emulationstation")))


def replace_old_screenshot(path, artwork):
    if path.resolve() != path or not path.is_file() or path.stat().st_size != OLD_SIZE:
        return
    with path.open("rb") as source:
        original = os.fstat(source.fileno())
        if hashlib.sha256(source.read()).hexdigest() != OLD_SHA256:
            return
    with NamedTemporaryFile(dir=path.parent, delete=False) as output:
        temporary = Path(output.name)
    try:
        temporary.write_bytes(artwork.read_bytes())
        temporary.chmod(original.st_mode & 0o777)
        current = path.lstat()
        if (os.path.samestat(original, current) and current.st_size == original.st_size
                and current.st_mtime_ns == original.st_mtime_ns):
            temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)


def register_running_image(shortcut, artwork):
    # AmberELEC's loopback API changes only this game's image in the live frontend.
    with closing(HTTPConnection("127.0.0.1", 1234, timeout=.5)) as connection:
        connection.request("GET", "/runningGame")
        response = connection.getresponse()
        if response.status != 200:
            return False
        game = json.loads(response.read(65536))
        if (not isinstance(game, dict) or game.get("systemName") != "ports"
                or game.get("image") or game.get("thumbnail")
                or not re.fullmatch("[0-9a-f]{32}", str(game.get("id", "")))):
            return True
        running = Path(game.get("path") or "")
        if not running.is_file() or not running.samefile(shortcut):
            return True
        connection.request("POST", "/systems/ports/games/" + game["id"] + "/media/image",
                           body=artwork.read_bytes(), headers={"Content-Type": "image/png"})
        return connection.getresponse().status == 200


def with_image(markup, game_index):
    """Splice only our image/entry. Keep comments, formatting and all other XML bytes."""
    tag = f"<image>./{DEFAULT_IMAGE}</image>".encode("ascii")
    game = b"<game><path>./AM2ARM.sh</path><name>AM2ARM</name>" + tag + b"</game>"
    if markup is None:
        return b'<?xml version="1.0"?>\n<gameList>\n' + game + b"\n</gameList>\n"
    if b"\0" in markup:
        return markup  # Leave non-ASCII-compatible encodings to the frontend.

    parser = expat.ParserCreate()
    stack, ends = [], []
    image_span = None
    root_end = 0

    def start(name, attributes):
        stack.append((name, parser.CurrentByteIndex))

    def end(name):
        nonlocal image_span, root_end
        _, opening = stack.pop()
        offset = parser.CurrentByteIndex
        if not stack:
            root_end = offset
        elif len(stack) == 1 and name == "game":
            ends.append(offset)
        elif (len(stack) == 2 and stack[1][0] == "game" and name == "image"
              and len(ends) == game_index and image_span is None):
            # Expat reports the closing tag's start, or the byte after a self-closing tag.
            finish = markup.index(b">", offset)+1 if markup.startswith(b"</image", offset) else offset
            image_span = opening, finish

    parser.StartElementHandler, parser.EndElementHandler = start, end
    parser.Parse(markup, True)
    if image_span is not None:
        first, last = image_span
        return markup[:first] + tag + markup[last:]
    if game_index is not None:
        pos = ends[game_index]
        return markup[:pos] + tag + markup[pos:]
    if markup.startswith(b"</", root_end):
        return markup[:root_end] + game + b"\n" + markup[root_end:]
    return markup[:root_end-2] + b">\n" + game + b"\n</gameList>" + markup[root_end:]


def register_offline(gamelist, markup, game_index, artwork):
    # Both EmulationStation variants recognize this local image name.
    local = gamelist.parent/DEFAULT_IMAGE
    local.parent.mkdir(exist_ok=True)
    try:
        with local.open("xb") as output:
            output.write(artwork.read_bytes())
    except FileExistsError:
        if not is_bundled_image(local, artwork):
            return
    # A new ROM-local gamelist takes precedence over the firmware's existing list.
    if markup is None and any(catalog.is_file() for catalog in OTHER_CATALOGS):
        return
    updated = with_image(markup, game_index)
    if markup is None:
        with gamelist.open("xb") as output:
            output.write(updated)
        return
    if markup == updated or gamelist.is_symlink():
        return
    backup = gamelist.with_suffix(".xml.am2arm.bak")
    try:
        with backup.open("xb") as output:
            output.write(markup)
    except FileExistsError:
        pass
    with NamedTemporaryFile(dir=gamelist.parent, delete=False) as output:
        temporary = Path(output.name)
    try:
        temporary.write_bytes(updated)
        temporary.chmod(gamelist.stat().st_mode & 0o777)
        if gamelist.read_bytes() == markup:
            temporary.replace(gamelist)
    finally:
        temporary.unlink(missing_ok=True)


def is_bundled_image(path, artwork):
    return (not path.is_symlink() and path.is_file() and path.stat().st_size == artwork.stat().st_size
            and path.read_bytes() == artwork.read_bytes())


def prepare_ports_art(ports, app):
    try:
        ports = ports.resolve()
        shortcut = ports/"AM2ARM.sh"
        artwork = app/"patcher/assets/ports-thumbnail.png"
        if not shortcut.is_file() or not artwork.is_file():
            return
        gamelist = ports/"gamelist.xml"
        markup = gamelist.read_bytes() if gamelist.is_file() else None
        game_index = None
        if markup is not None:
            catalog = ElementTree.fromstring(markup)
            if catalog.tag != "gameList":
                return
            for i, game in enumerate(catalog.findall("game")):
                entry = Path(game.findtext("path", ""))
                if entry.name != shortcut.name or (ports/entry).resolve() != shortcut.resolve():
                    continue
                media = [(ports/item.text.strip()).resolve() for item in game
                         if item.tag in ("image", "thumbnail") and item.text and item.text.strip()]
                if media:
                    legacy = ports/"am2arm/screenshot.png"
                    if legacy in media:
                        replace_old_screenshot(legacy, artwork)
                    return
                game_index = i
                break
        images = ports/"images"
        # ES's media API writes images/AM2ARM-image.png. Honor existing local artwork, too.
        if images.is_symlink():
            return
        for path in images.glob("AM2ARM*"):
            if path.stem in ("AM2ARM", "AM2ARM-image", "AM2ARM-thumb"):
                if path != ports/DEFAULT_IMAGE or not is_bundled_image(path, artwork):
                    return
        try:
            if register_running_image(shortcut, artwork):
                return
        except (OSError, HTTPException, ValueError):
            pass
        register_offline(gamelist, markup, game_index, artwork)
    except (OSError, RuntimeError, ValueError, TypeError, HTTPException, ElementTree.ParseError, expat.ExpatError):
        # Art is optional on read-only cards or when the frontend is unavailable.
        return
