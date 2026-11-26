"""Build the AM2ARM Launcher from the published 1.6.3 Linux package."""
import argparse
from copy import copy
import csv
import hashlib
from io import BytesIO
import os
from pathlib import Path
import shutil
import subprocess
from tempfile import NamedTemporaryFile
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo
from knulli_image import IMAGE, add_image


BASE_SHA256 = "4c3661d8fbbfe236ef550a8816ee5199ced7034df2b1d8f5584f3bd09b4ea5c1"
RUNTIME = "am2arm-launcher/AM2ARM/runtime/"
SOURCE = Path(__file__).parent / "launcher"
WESTON_SHA256 = "0bccaeebc11296bb1fe4278c9677cb82965c5a04bcd63745fa09d78228bc1a93"
WESTON_FILES = {
    "lib_aarch64/graphics/gl4es_glxpass/libGL.so.1":
        "9cbb229668731a4e9504873b0e8634d5ee83c4936ef3c2ec8290db7ac2bbff7b",
    "lib_aarch64/graphics/crusty_glx/libcrusty.so":
        "e469163f8937004fffb98243c836cf4c896943d96a882cec6071c1650aab5c8c",
}


def ports_thumbnail(archive):
    """Make a 4:3 Ports preview from the launcher's own title screen and logo."""
    from PIL import Image, ImageEnhance, ImageOps
    assets = "am2arm-launcher/AM2ARM/patcher/assets/"
    with Image.open(BytesIO(archive.read(assets + "title-background.png"))) as planet:
        cover = ImageOps.fit(planet.convert("RGB"), (480, 360), Image.Resampling.NEAREST,
                             centering=(.5, 1))
    cover = ImageEnhance.Brightness(cover).enhance(.64)
    with Image.open(BytesIO(archive.read(assets + "am2arm-banner.png"))) as banner:
        logo = banner.crop(banner.getbbox())
        logo.thumbnail((430, cover.height), Image.Resampling.LANCZOS)
        cover.paste(logo, ((cover.width-logo.width)//2, (cover.height-logo.height)//2), logo)
    preview = BytesIO()
    cover.save(preview, format="PNG")
    return preview.getvalue()


def offline_graphics(image):
    with image.open("rb") as stream:
        if hashlib.file_digest(stream, "sha256").hexdigest() != WESTON_SHA256:
            raise ValueError("The display runtime must be the original Westonpack 0.2.7.1 image.")
    files = {}
    for source, checksum in WESTON_FILES.items():
        data = subprocess.check_output(["unsquashfs", "-cat", str(image), source])
        if hashlib.sha256(data).hexdigest() != checksum:
            raise ValueError(f"Unexpected display library: {source}")
        files[RUNTIME + "graphics/" + Path(source).name] = data
    return files


def runtime_inventory(archive, audio_rows):
    prefix = "am2arm-launcher/dependencies/"
    lines = archive.read(prefix + "inventory.tsv").decode().splitlines(keepends=True)
    sources = archive.read(prefix + "westonpack.tsv").decode().splitlines()
    additions = []
    for member in csv.DictReader(sources, delimiter="\t"):
        source = member["external_squashfs_member"]
        if member["sha256"] != WESTON_FILES[source]:
            raise ValueError(f"Unexpected inventory checksum for {source}")
        path = "runtime/graphics/" + Path(source).name
        fields = ("launcher", path, member["architecture"], "DYN", member["bytes"], member["sha256"],
                  "Westonpack 0.2.7.1", source, member["sha256"], member["needed_sonames"])
        additions.append("\t".join(fields) + "\n")
    first_edition = next(i for i, line in enumerate(lines) if line.startswith("standard\t"))
    lines[first_edition:first_edition] = additions + [line.rstrip("\n") + "\n" for line in audio_rows]
    return "".join(lines).encode()


def adapt_display_session(original):
    changes = (
        (b"        game = Path(os.environ['AM2ARM_PLAY_DIR']) if os.environ.get('AM2ARM_PLAY_DIR') else installed_game(CARD)\n",
         b"        game = Path(os.environ['AM2ARM_PLAY_DIR']) if os.environ.get('AM2ARM_PLAY_DIR') else installed_game(CARD)\n"
         b"        if json.loads((game/'edition.json').read_text())['edition'] == 'dual-screen':\n"
         b"            os.environ['AM2ARM_DISPLAY_NOTICE'] = 'dual-screen'\n"
         b"            mode = 'patcher'\n"),
        (b"from nextui_controls import brick_mappings, evdev_mapping\n",
         b"from trimui_device import brick_mappings, panel_mapping\n"),
        (b"        mappings += '\\n'+evdev_mapping(device)\n",
         b"        mappings += '\\n'+panel_mapping(device)\n"),
        (b"from trimui_device import current_device, display_size\n",
         b"from trimui_device import current_device, display_size, firmware_audio_session, firmware_display_loader\n"),
        (b"            if device in AMBERELEC_PANELS:\n                resources.callback(cleanup)\n",
         b"            audio = firmware_audio_session(device)\n"
         b"            if audio is not None:\n"
         b"                resources.enter_context(audio(env, work, logs/(stamp+'-audio.log')))\n"
         b"                resources.callback(cleanup)\n"
         b"            elif device in AMBERELEC_PANELS:\n                resources.callback(cleanup)\n"),
        (b"    # AmberELEC's SDL requires its glibc, and its libcurl requires its OpenSSL.\n"
         b"    firmware_abi = os.environ.get('AM2ARM_DEVICE_PROFILE') in AMBERELEC_PANELS\n"
         b"    loader = (Path('/usr/lib') if firmware_abi else core)/'ld-linux-aarch64.so.1'\n",
         b"    loader = firmware_display_loader(os.environ.get('AM2ARM_DEVICE_PROFILE'))\n"
         b"    firmware_abi = loader is not None\n"
         b"    if loader is None:\n"
         b"        loader = core/'ld-linux-aarch64.so.1'\n"),
    )
    for previous, updated in changes:
        if original.count(previous) != 1:
            raise ValueError("Unrecognized direct display session in the base package.")
        original = original.replace(previous, updated)
    return original


def classify_original_zip_errors(source):
    """Expose donor verification failures to the menu while keeping the patch format intact."""
    declaration = b"class PatchError(Exception):\n    pass\n"
    start = source.index(b"def locate_datawin(")
    end = source.index(b"def patch(", start)
    member_error = b'raise PatchError(f"file from your 1.1 copy failed verification:'
    if source.count(declaration) != 1 or source.count(member_error) != 1:
        raise ValueError("Unrecognized source verification in the base patcher.")
    prefix = source[:start].replace(declaration, declaration + b"\n\nclass OriginalZipError(PatchError):\n    pass\n")
    validators = source[start:end].replace(b"raise PatchError(", b"raise OriginalZipError(")
    assembly = source[end:].replace(member_error, member_error.replace(b"PatchError", b"OriginalZipError"))
    return prefix + validators + assembly


def respect_completion_notice(source):
    """Allow an edition-specific completion notice to keep the picker open."""
    old = b"                self.installed(message[1], message[2])\n                if self.closed:\n                    return\n"
    if source.count(old) != 1:
        raise ValueError("Unrecognized installation completion in the handheld menu.")
    return source.replace(old, old + b"                if self.notice is not None:\n                    continue\n")


def build(base, output, westonpack, darkos_audio):
    from darkos_audio_bundle import read_bundle
    if output.resolve() in {base.resolve(), westonpack.resolve(), darkos_audio.resolve()}:
        raise ValueError("Choose an output path separate from the build inputs.")
    with base.open("rb") as stream:
        if hashlib.file_digest(stream, "sha256").hexdigest() != BASE_SHA256:
            raise ValueError("The input differs from the verified standalone 1.6.3 package.")
    bundled_files = offline_graphics(westonpack)
    audio_files, audio_rows = read_bundle(darkos_audio)
    bundled_files.update({RUNTIME + name: data for name, data in audio_files.items()})
    for name in ("darkos_audio.py", "muos_audio.py"):
        bundled_files[RUNTIME + name] = (SOURCE / name).read_bytes()
    bundled_files[RUNTIME + "ports_art.py"] = (SOURCE / "ports_art.py").read_bytes()
    dependencies = SOURCE / "dependencies"
    if not dependencies.is_dir():
        dependencies = Path(__file__).resolve().parents[2] / "native/unified/menus/dependencies"
    bundled_files[RUNTIME + "licenses/PortMaster-New.txt"] = (dependencies / "notices/PortMaster-New.txt").read_bytes()
    bundled_files["AM2ARM/README.txt"] = (SOURCE / "original-folder.txt").read_bytes()
    replacements = {RUNTIME + name: (SOURCE / name).read_bytes()
                    for name in ("first_run.py", "first_run_gui.py", "nextui_gui.py", "route.py", "session.sh", "trimui_device.py", "weston_graphics.py")}
    replacements["AM2ARM-READ-ME.txt"] = (SOURCE / "AM2ARM-READ-ME.txt").read_bytes()
    replacements["am2arm-launcher/dependencies/README.md"] = (dependencies / "README.md").read_bytes()
    replacements["am2arm-launcher/AM2ARM/patcher/input/README.txt"] = (
        b"Put your Windows AM2R 1.1 ZIP in the AM2ARM folder beside AM2ARM-READ-ME.txt on the game card.\n"
        b"Older installations can keep their original ZIP in this input folder.\n")
    preserved = {RUNTIME + "first_run.py": "installation.py"}
    retired = {f"{directory}/AM2ARM Editions.sh" for directory in ("ports", "roms/ports")}
    output.parent.mkdir(parents=True, exist_ok=True)
    with NamedTemporaryFile(dir=output.parent, suffix=".part", delete=False) as tmp:
        staging = Path(tmp.name)
    try:
        with ZipFile(base) as original, ZipFile(staging, "w") as result:
            bundled_files["am2arm-launcher/AM2ARM/patcher/assets/ports-thumbnail.png"] = ports_thumbnail(original)
            replacements["am2arm-launcher/dependencies/inventory.tsv"] = runtime_inventory(original, audio_rows)
            card_script = (SOURCE / "knulli_card.sh").read_bytes()
            for directory in ("ports", "roms/ports"):
                entry = f"{directory}/AM2ARM.sh"
                script = original.read(entry)
                suffix = b'exec /bin/sh "$card/am2arm-launcher/launch.sh" auto "$@"\n'
                if not script.endswith(suffix):
                    raise ValueError("Unrecognized Ports shortcut: " + entry)
                replacements[entry] = (script[:-len(suffix)] + b'set -- auto "$@"\n'
                                       + card_script + b'\nexec /bin/sh "$card/am2arm-launcher/launch.sh" "$@"\n')
            compat = RUNTIME + "compat_display.py"
            replacements[compat] = original.read(compat).replace(b"card/'Persistent/portmaster/lib', ", b"")
            session = RUNTIME + "nextui_session.py"
            replacements[session] = adapt_display_session(original.read(session))
            core = "am2arm-launcher/AM2ARM/patcher/patch_core.py"
            replacements[core] = classify_original_zip_errors(original.read(core))
            gui = "am2arm-launcher/AM2ARM/patcher/handheld_gui.py"
            replacements[gui] = respect_completion_notice(original.read(gui))
            for info in original.infolist():
                if info.filename in retired:
                    continue
                if info.filename.endswith(".sh") and info.filename.split("/", 1)[0] in ("ports", "roms", "Apps", "App", "Tools"):
                    shortcut = replacements.get(info.filename) or original.read(info)
                    replacements[info.filename] = shortcut.replace(b"export AM2ARM_FETCH_DISPLAY=1\n", b"")
                if info.filename in replacements:
                    result.writestr(copy(info), replacements[info.filename])
                    if info.filename in preserved:
                        module = copy(info)
                        module.filename = RUNTIME + preserved[info.filename]
                        result.writestr(module, original.read(info))
                else:
                    with original.open(info) as source, result.open(copy(info), "w") as target:
                        shutil.copyfileobj(source, target, length=1024*1024)
            entry = ZipInfo("AM2ARM/")
            entry.create_system = 3
            entry.external_attr = (0o40755 << 16) | 0x10
            result.writestr(entry, b"")
            for name, data in bundled_files.items():
                member = ZipInfo(name)
                member.create_system = 3
                executable = name.endswith(".sh") or name.startswith(RUNTIME + "darkos-audio/bin/")
                member.external_attr = (0o100755 if executable else 0o100644) << 16
                result.writestr(member, data, compress_type=ZIP_DEFLATED)
            result.comment = original.comment
        add_image(staging)
        with ZipFile(base) as original, ZipFile(staging) as result:
            expected = (set(original.namelist()) - retired) | bundled_files.keys() | {"AM2ARM/", IMAGE, *(RUNTIME + name for name in preserved.values())}
            if len(result.infolist()) != len(expected) or set(result.namelist()) != expected:
                raise ValueError("Unexpected package contents.")
            for info in original.infolist():
                if info.filename not in replacements and info.filename not in retired:
                    other = result.getinfo(info.filename)
                    if (info.CRC, info.file_size, info.external_attr) != (other.CRC, other.file_size, other.external_attr):
                        raise ValueError(f"Changed original package member: {info.filename}")
            for original_name, name in preserved.items():
                if result.read(RUNTIME + name) != original.read(original_name):
                    raise ValueError(f"Changed installation module: {name}")
            for name, data in bundled_files.items():
                if result.read(name) != data:
                    raise ValueError(f"Invalid bundled file: {name}")
            if (bad := result.testzip()) is not None:
                raise ValueError(f"Unusable ZIP entry: {bad}")
        staging.chmod(0o644)
        staging.replace(output)
    finally:
        staging.unlink(missing_ok=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("base", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--westonpack", type=Path, default=os.environ.get("AM2ARM_WESTONPACK"),
                        help="Westonpack 0.2.7.1 build input (or set AM2ARM_WESTONPACK).")
    parser.add_argument("--darkos-audio", type=Path, default=os.environ.get("AM2ARM_DARKOS_AUDIO"),
                        help="Verified Debian ARM64 audio bundle produced by darkos_audio_bundle.py.")
    args = parser.parse_args()
    if args.westonpack is None:
        parser.error("Supply --westonpack or set AM2ARM_WESTONPACK.")
    if args.darkos_audio is None:
        parser.error("Supply --darkos-audio or set AM2ARM_DARKOS_AUDIO.")
    build(args.base, args.output, args.westonpack, args.darkos_audio)
    print(args.output)
