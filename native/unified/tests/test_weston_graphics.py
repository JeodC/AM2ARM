import hashlib
import io
import tempfile
import unittest
import zlib
from pathlib import Path
from unittest.mock import patch
from urllib.error import URLError
from urllib.response import addinfourl

import weston_graphics as weston


class WestonGraphicsTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.card = Path(temporary.name)
        self.runtime = self.card/'tools/runtime'
        self.manager = self.card/'separate-tools/PortMaster'
        self.env = {'AM2ARM_PORTMASTER_DIR': str(self.manager)}
        self.files = {'libGL.so.1': b'gl4es' * 50000, 'libcrusty.so': b'display helper'}
        image = bytearray(b'example image')
        members = {}
        for name, content in self.files.items():
            members[name] = (len(image), len(content), hashlib.sha256(content).hexdigest())
            for start in range(0, len(content), weston.BLOCK_SIZE):
                image.extend(zlib.compress(content[start:start + weston.BLOCK_SIZE]))
        self.image = bytes(image)
        replacements = patch.multiple(weston, MEMBERS=members, IMAGE_SIZE=len(image),
                                     IMAGE_SHA256=hashlib.sha256(image).hexdigest())
        replacements.start()
        self.addCleanup(replacements.stop)

    def test_split_portmaster_path_and_offline_repeat(self):
        source = self.manager/'libs'/weston.IMAGE
        source.parent.mkdir(parents=True)
        source.write_bytes(self.image)
        cache = weston.locate_graphics(self.card, self.runtime, self.env)
        self.assertEqual({p.name: p.read_bytes() for p in cache.iterdir()}, self.files)
        source.unlink()
        self.assertEqual(weston.locate_graphics(self.card, self.runtime, self.env), cache)
        (cache/'libcrusty.so').write_bytes(b'x' * len(self.files['libcrusty.so']))
        with self.assertRaisesRegex(RuntimeError, 'Westonpack'):
            weston.locate_graphics(self.card, self.runtime, self.env)

    def test_invalid_card_image_is_never_used(self):
        (self.card/weston.IMAGE).write_bytes(b'x' * len(self.image))
        with self.assertRaisesRegex(RuntimeError, 'Westonpack'):
            weston.locate_graphics(self.card, self.runtime, self.env)
        self.assertFalse((self.card/'AM2ARM-data').exists())

    def test_older_verified_card_copy_is_reused_without_writes(self):
        old = self.card/'AM2ARM/runtime/graphics'
        old.mkdir(parents=True)
        for name, content in self.files.items():
            (old/name).write_bytes(content)
        self.assertEqual(weston.locate_graphics(self.card, self.runtime, self.env), old)
        self.assertFalse((self.card/'AM2ARM-data').exists())

    def test_first_download_then_offline_launch_without_a_manager(self):
        messages = []
        response = addinfourl(io.BytesIO(self.image), {}, 'https://example.org/runtime')
        with patch('urllib.request.urlopen', return_value=response) as fetch:
            cache = weston.prepare_graphics(self.card, self.runtime, {}, lambda *msg: messages.append(msg))
            self.assertEqual({p.name: p.read_bytes() for p in cache.iterdir()}, self.files)
            self.assertTrue(messages)
            self.assertEqual(messages[-1][:2], (len(self.image), len(self.image)))
            self.assertTrue(fetch.call_args.args[0].startswith('https://'))
            self.assertEqual(weston.prepare_graphics(self.card, self.runtime, {}, self.fail), cache)
            fetch.assert_called_once()

    def test_failed_transfer_can_be_recovered_with_the_card_image(self):
        progress = lambda *_: None
        for data in (self.image[:-1], self.image + b'x', b'x' + self.image[1:]):
            response = addinfourl(io.BytesIO(data), {}, 'https://example.org/runtime')
            with self.subTest(size=len(data)), patch('urllib.request.urlopen', return_value=response):
                with self.assertRaisesRegex(weston.WestonpackRequired, weston.IMAGE):
                    weston.prepare_graphics(self.card, self.runtime, {}, progress)
                self.assertFalse(any(p.is_file() for p in self.card.rglob('*')))
        with patch('urllib.request.urlopen', side_effect=URLError('offline')) as fetch:
            with self.assertRaisesRegex(weston.WestonpackRequired, weston.IMAGE):
                weston.prepare_graphics(self.card, self.runtime, {}, progress)
            (self.card/weston.IMAGE).write_bytes(self.image)
            cache = weston.prepare_graphics(self.card, self.runtime, {}, self.fail)
            self.assertTrue(weston.verified_pair(cache))
            fetch.assert_called_once()
