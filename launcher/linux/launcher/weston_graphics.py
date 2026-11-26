"""Verify AM2ARM's bundled display libraries and recover earlier offline installs."""
import hashlib
import os
from pathlib import Path
import tempfile
import zlib


IMAGE = 'weston_pkg_0.2.squashfs'
IMAGE_SIZE = 55398400
IMAGE_SHA256 = '0bccaeebc11296bb1fe4278c9677cb82965c5a04bcd63745fa09d78228bc1a93'
BLOCK_SIZE = 131072
# The pinned SquashFS stores each of these files in consecutive zlib streams.
# The offsets apply only after authenticating the whole image.
MEMBERS = {
    'libGL.so.1': (12760988, 7147064, '9cbb229668731a4e9504873b0e8634d5ee83c4936ef3c2ec8290db7ac2bbff7b'),
    'libcrusty.so': (12583229, 206240, 'e469163f8937004fffb98243c836cf4c896943d96a882cec6071c1650aab5c8c'),
}
SETUP_MESSAGE = ('AM2ARM display files are missing or damaged. '
                 'Re-extract the complete launcher ZIP into your game library.')


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
    for path in (runtime/'graphics', cache, card/'AM2ARM/runtime/graphics',
                 card/'am2arm-launcher/AM2ARM/runtime/graphics', ports/'am2arm-launcher/AM2ARM/runtime/graphics'):
        if verified_pair(path):
            return path

    # Earlier offline installs may still have the verified image on the game card.
    for path in (card/'AM2ARM'/IMAGE, card/IMAGE):
        if not path.is_file():
            continue
        with path.open('rb') as source:
            if cache_image(source, cache):
                return cache
    raise WestonpackRequired(SETUP_MESSAGE)


def prepare_graphics(card, runtime, environment, progress):
    return locate_graphics(card, runtime, environment)
