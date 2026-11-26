"""Package the read-only tools used on KNULLI Brick's exFAT game volume."""
from pathlib import Path
import shutil
import subprocess
from tempfile import TemporaryDirectory
from zipfile import ZipFile, ZipInfo


IMAGE = "am2arm-launcher/knulli-runtime.squashfs"


def add_image(archive_path):
    with TemporaryDirectory(dir=archive_path.parent) as temporary:
        root = Path(temporary) / "root"
        image = Path(temporary) / "runtime.squashfs"
        with ZipFile(archive_path) as archive:
            for member in archive.infolist():
                name = member.filename
                if not name.startswith("am2arm-launcher/") or "/patch-bundle/" in name:
                    continue
                target = root / name
                if member.is_dir():
                    target.mkdir(parents=True, exist_ok=True)
                    continue
                target.parent.mkdir(parents=True, exist_ok=True)
                with archive.open(member) as source, target.open("wb") as output:
                    shutil.copyfileobj(source, output)
                target.chmod((member.external_attr >> 16) & 0o777 or 0o644)
        for folder in ("logs", "patcher/input", "patcher/patch-bundle"):
            (root / "am2arm-launcher/AM2ARM" / folder).mkdir(parents=True, exist_ok=True)
        subprocess.run(["mksquashfs", root, image, "-noappend", "-all-root", "-no-xattrs",
                        "-comp", "gzip", "-mkfs-time", "946684800", "-inode-time", "946684800",
                        "-processors", "3", "-quiet", "-no-progress"], check=True)
        with ZipFile(archive_path, "a") as archive:
            info = ZipInfo(IMAGE)
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            archive.writestr(info, image.read_bytes())
