"""Find and verify the two display libraries used from Westonpack 0.2.7.1."""
import hashlib
import os
from pathlib import Path
import tempfile
import zlib


IMAGE = 'weston_pkg_0.2.squashfs'
IMAGE_URL = 'https://github.com/PortsMaster/PortMaster-New/releases/download/2025-07-24_0745/' + IMAGE
IMAGE_SIZE = 55398400
IMAGE_SHA256 = '0bccaeebc11296bb1fe4278c9677cb82965c5a04bcd63745fa09d78228bc1a93'
BLOCK_SIZE = 131072
# The pinned SquashFS stores each of these files in consecutive zlib streams.
# The offsets apply only after authenticating the whole image.
MEMBERS = {
    'libGL.so.1': (12760988, 7147064, '9cbb229668731a4e9504873b0e8634d5ee83c4936ef3c2ec8290db7ac2bbff7b'),
    'libcrusty.so': (12583229, 206240, 'e469163f8937004fffb98243c836cf4c896943d96a882cec6071c1650aab5c8c'),
}
SETUP_MESSAGE = ('This display uses Westonpack 0.2.7.1. Copy its official '
                 'weston_pkg_0.2.squashfs beside AM2R_11.zip on your game card, '
                 'or into PortMaster/libs. Keep the file intact, then reopen AM2ARM.')


class WestonpackRequired(RuntimeError):
    pass


def verified_pair(directory):
    try:
        for name, (_, size, expected) in MEMBERS.items():
            path = directory/name
            if not path.is_file() or path.stat().st_size != size:
                return False
            with path.open('rb') as source:
                if hashlib.file_digest(source, 'sha256').hexdigest() != expected:
                    return False
        return True
    except OSError:
        return False


def extract_pair(source, destination):
    for name, (start, remaining, expected) in MEMBERS.items():
        source.seek(start)
        checksum = hashlib.sha256()
        with (destination/name).open('xb') as output:
            while remaining:
                length = min(remaining, BLOCK_SIZE)
                decoder = zlib.decompressobj()
                data = decoder.decompress(source.read(BLOCK_SIZE + 128), length + 1)
                if len(data) != length or not decoder.eof:
                    raise ValueError('Unexpected Westonpack data block.')
                source.seek(-len(decoder.unused_data), os.SEEK_CUR)
                output.write(data)
                checksum.update(data)
                remaining -= length
        if checksum.hexdigest() != expected:
            raise ValueError('Westonpack graphics verification failed.')


def cache_image(source, cache):
    if os.fstat(source.fileno()).st_size != IMAGE_SIZE:
        return False
    source.seek(0)
    if hashlib.file_digest(source, 'sha256').hexdigest() != IMAGE_SHA256:
        return False
    cache.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=cache.parent) as temporary:
        pending = Path(temporary)
        extract_pair(source, pending)
        cache.mkdir(exist_ok=True)
        for name in MEMBERS:
            os.replace(pending/name, cache/name)
    return True


def locate_graphics(card, runtime, environment):
    ports = Path(environment.get('AM2ARM_PORTS_DIR') or card/'ports')
    cache = card/'AM2ARM-data/runtime/weston-0.2.7.1'
    # Previous card and PortMaster installs can supply the same upstream files.
    for path in (cache, runtime/'graphics', card/'AM2ARM/runtime/graphics',
                 card/'am2arm-launcher/AM2ARM/runtime/graphics', ports/'am2arm-launcher/AM2ARM/runtime/graphics'):
        if verified_pair(path):
            return path

    managers = [ports/'PortMaster', card/'ports/PortMaster', Path('/opt/system/Tools/PortMaster')]
    configured = environment.get('AM2ARM_PORTMASTER_DIR')
    if configured:
        managers.insert(0, Path(configured))
    images = [path/'libs'/IMAGE for path in managers] + [card/IMAGE]
    for path in dict.fromkeys(images):
        if not path.is_file():
            continue
        with path.open('rb') as source:
            if cache_image(source, cache):
                return cache
    raise WestonpackRequired(SETUP_MESSAGE)


def prepare_graphics(card, runtime, environment, progress):
    try:
        return locate_graphics(card, runtime, environment)
    except WestonpackRequired:
        pass

    from http.client import HTTPException
    import ssl
    from urllib.request import urlopen

    cache = card/'AM2ARM-data/runtime/weston-0.2.7.1'
    label = 'Downloading display support (53 MiB)…'
    progress(0, IMAGE_SIZE, label)
    try:
        cache.parent.mkdir(parents=True, exist_ok=True)
        context = ssl.create_default_context()
        context.load_verify_locations(cafile=str(Path(__file__).parent/'certificates/mozilla.pem'))
        with tempfile.TemporaryFile(dir=cache.parent) as image:
            with urlopen(IMAGE_URL, timeout=12, context=context) as response:
                if not response.geturl().startswith('https://'):
                    raise ValueError('The display download requires HTTPS.')
                received = 0
                while received < IMAGE_SIZE:
                    data = response.read(min(256 * 1024, IMAGE_SIZE - received))
                    if not data:
                        break
                    image.write(data)
                    received += len(data)
                    progress(received, IMAGE_SIZE, label)
                if received != IMAGE_SIZE or response.read(1):
                    raise ValueError('Unexpected display download size.')
            image.flush()
            if not cache_image(image, cache):
                raise ValueError('Display download checksum mismatch.')
        return cache
    except (OSError, ValueError, HTTPException, zlib.error) as error:
        print('Westonpack setup:', type(error).__name__, str(error), flush=True)
        raise WestonpackRequired(
            'Display support could not be downloaded or verified. Connect to the internet and reopen AM2ARM, '
            'or copy weston_pkg_0.2.squashfs beside your original game ZIP. The download link is in AM2ARM-READ-ME.txt.'
        ) from error
