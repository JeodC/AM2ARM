"""Rebuild the dArkOS G350 audio bundle from pinned Debian ARM64 packages."""
import argparse
import hashlib
import io
import os
from pathlib import Path
import re
import shutil
import subprocess
import tarfile
from tempfile import NamedTemporaryFile, TemporaryDirectory
from urllib.request import urlopen
from zipfile import ZipFile, ZipInfo

from launcher.darkos_audio import FILES


BUNDLE_SHA256 = '5a4bb8aa26ac6fa6793e42726e8e924b32f633be4ded3953dcd1a8d66ee99c3f'
DEBIAN = 'https://deb.debian.org/debian/'
PULSE = 'pool/main/p/pulseaudio/'
ORC = 'pool/main/o/orc/'
DAEMON = PULSE + 'pulseaudio_17.0+dfsg1-2+b1_arm64.deb'
UTILS = PULSE + 'pulseaudio-utils_17.0+dfsg1-2+b1_arm64.deb'
ORC_LIB = ORC + 'liborc-0.4-0t64_0.4.41-1_arm64.deb'
PULSE_SRC = PULSE + 'pulseaudio_17.0+dfsg1.orig.tar.xz'
# From the binary-arm64 and source SHA256 indexes of Debian's signed 13.8 InRelease.
INPUTS = {
    DAEMON: 'e0ee9b8ce8053d387a4ce030a2fe68484c96035f1589eb3af6f62e084a36840c',
    UTILS: '0a617395416f70892ff06fe7c2a6b28db1f66f7fe722f63fd5cc7fb4beba37d1',
    ORC_LIB: 'e69ee68606246657ff19bfe13058a9aef177e686b97638728f9e0e911af07680',
    PULSE_SRC: '24a25d3cf8fcede801f6b3d05ca6d22b0a43ad2f710a4fbf2ec251debc9cff5b',
}
MODULE_DIR = 'usr/lib/pulse-17.0+dfsg1/modules/'
MEMBERS = {
    DAEMON: {
        'usr/bin/pulseaudio': 'bin/pulseaudio',
        'usr/lib/aarch64-linux-gnu/pulseaudio/libpulsecore-17.0.so': 'lib/libpulsecore-17.0.so',
        **{MODULE_DIR + name: 'modules/' + name for name in (
            'module-alsa-sink.so', 'module-native-protocol-unix.so', 'libalsa-util.so', 'libprotocol-native.so')},
        'usr/share/doc/pulseaudio/copyright': 'licenses/pulseaudio-copyright',
    },
    UTILS: {'usr/bin/pactl': 'bin/pactl',
            'usr/share/doc/pulseaudio-utils/copyright': 'licenses/pulseaudio-utils-copyright'},
    ORC_LIB: {'usr/lib/aarch64-linux-gnu/liborc-0.4.so.0.41.0': 'lib/liborc-0.4.so.0',
              'usr/share/doc/liborc-0.4-0t64/copyright': 'licenses/orc-copyright'},
    PULSE_SRC: {'pulseaudio-17.0/GPL': 'licenses/GPL-2', 'pulseaudio-17.0/LGPL': 'licenses/LGPL-2.1',
                'pulseaudio-17.0/LICENSE': 'licenses/PulseAudio-LICENSE'},
}


def input_file(directory, upstream, fetch):
    path = directory / Path(upstream).name
    if not path.exists() and fetch:
        directory.mkdir(parents=True, exist_ok=True)
        with TemporaryDirectory(dir=directory) as temp:
            pending = Path(temp) / path.name
            with urlopen(DEBIAN + upstream, timeout=45) as download, pending.open('xb') as output:
                shutil.copyfileobj(download, output)
            if hashlib.sha256(pending.read_bytes()).hexdigest() != INPUTS[upstream]:
                raise ValueError(f'Downloaded SHA-256 differs from Debian for {path.name}')
            try:
                os.link(pending, path)
            except FileExistsError:
                pass  # Concurrent downloads must pass the same digest check below.
    if hashlib.sha256(path.read_bytes()).hexdigest() != INPUTS[upstream]:
        raise ValueError(f'Unexpected Debian input checksum for {path.name}')
    return path


def inventory_row(data, original, name, package):
    if data[:6] != b'\x7fELF\x02\x01' or data[16:20] != b'\x03\0\xb7\0':
        raise ValueError(f'Expected ARM64 little-endian ELF for {name}')
    digest = hashlib.sha256(data).hexdigest()
    if digest != FILES[name]:
        raise ValueError(f'Unexpected extracted ELF checksum for {name}')
    with NamedTemporaryFile() as elf:
        elf.write(data)
        elf.flush()
        dynamic = subprocess.check_output(['readelf', '--wide', '--dynamic', elf.name],
                                          text=True, env=dict(os.environ, LC_ALL='C'))
    needs = re.findall(r'\(NEEDED\).*?\[([^\]]+)\]', dynamic)
    return '\t'.join(('launcher', 'runtime/darkos-audio/' + name, 'AArch64 ELF64 little-endian', 'DYN',
                      str(len(data)), digest, 'Debian ' + Path(package).name, original, digest, ','.join(needs)))


def build_bundle(directory, output, fetch=False):
    files, rows = {}, []
    for package, mapping in MEMBERS.items():
        path = input_file(directory, package, fetch)
        if path.suffix == '.deb':
            content = subprocess.check_output(['ar', 'p', path, 'data.tar.xz'])
        else:
            content = path.read_bytes()
        with tarfile.open(fileobj=io.BytesIO(content), mode='r:xz') as tar:
            for source, name in mapping.items():
                original = './' + source if path.suffix == '.deb' else source
                member = tar.getmember(original)
                if not member.isfile():
                    raise ValueError(f'Expected regular package member {original}')
                data = tar.extractfile(member).read()
                files['darkos-audio/' + name] = data
                if name in FILES:
                    rows.append(inventory_row(data, source, name, package))
    if len(rows) != len(FILES):
        raise ValueError('Incomplete dArkOS audio inventory')
    sources = ['Debian trixie arm64. Each ELF is the unmodified package member listed in inventory.tsv.',
               'Matching dArkOS release: https://github.com/christianhaitian/dArkOS/releases/tag/v11172026',
               'Debian package inputs (SHA-256)', '']
    sources.extend(f'{digest}  {DEBIAN}{package}' for package, digest in INPUTS.items())
    sources += ['', 'Corresponding Debian source packages', DEBIAN + PULSE + 'pulseaudio_17.0+dfsg1-2.dsc',
                DEBIAN + ORC + 'orc_0.4.41-1.dsc', '']
    files['darkos-audio/SOURCES.txt'] = '\n'.join(sources).encode()
    files['inventory.tsv'] = ('\n'.join(sorted(rows)) + '\n').encode()
    output.parent.mkdir(parents=True, exist_ok=True)
    with TemporaryDirectory(dir=output.parent) as temp:
        pending = Path(temp) / 'bundle.zip'
        with ZipFile(pending, 'x') as archive:
            for name, data in sorted(files.items()):
                entry = ZipInfo(name, date_time=(2000, 1, 1, 0, 0, 0))
                entry.create_system = 3
                entry.external_attr = (0o100755 if name.startswith('darkos-audio/bin/') else 0o100644) << 16
                archive.writestr(entry, data)
        try:
            os.link(pending, output)
        except FileExistsError:
            if output.read_bytes() != pending.read_bytes():
                raise ValueError(f'Another file already exists at {output}') from None


def read_bundle(path):
    """Return runtime-relative file data and ten-column dependency inventory rows."""
    with Path(path).open('rb') as stream:
        if hashlib.file_digest(stream, 'sha256').hexdigest() != BUNDLE_SHA256:
            raise ValueError('Unexpected dArkOS audio bundle SHA-256 digest.')
        with ZipFile(stream) as archive:
            files = {name: archive.read(name) for name in archive.namelist() if name.startswith('darkos-audio/')}
            return files, archive.read('inventory.tsv').decode().splitlines()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('inputs', type=Path, help='Directory containing the four original Debian downloads')
    parser.add_argument('output', type=Path, help='New deterministic ZIP file')
    parser.add_argument('--fetch', action='store_true', help='Download missing inputs and verify the pinned hashes')
    args = parser.parse_args()
    build_bundle(args.inputs, args.output, args.fetch)
    print(hashlib.sha256(args.output.read_bytes()).hexdigest(), args.output)
