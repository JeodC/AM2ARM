from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from compat_display import identify, video_drivers, library_candidates


class Compatibility(unittest.TestCase):
    def test_two_firmwares_and_a_shared_soc(self):
        self.assertEqual(identify("MIYOO RK3566 355 V10 Board", "", "", ""), "flip")
        self.assertEqual(identify("sun50iw10", "Hardware : TG5040", "", ""), "smartpro")
        self.assertEqual(identify("sun50iw10", "Hardware : TG3040", "", ""), "brick")
        self.assertEqual(identify("sun50iw10", "", "SmartPro", ""), "smartpro")
        for board, cpu, name in [("Miyoo Mini Flip", "SStar", "Flip"), ("Unknown", "", ""),
                                  ("sun50iw10", "TG5050", "SmartPro"), ("Other RK3566", "", "")]:
            with self.assertRaises(RuntimeError):
                identify(board, cpu, name, "")

    def test_actual_direct_drivers(self):
        reported = ["wayland", "x11", "mali", "KMSDRM", "dummy", "offscreen"]
        self.assertEqual(video_drivers("flip", reported), ["KMSDRM", "mali"])
        self.assertEqual(video_drivers("smartpro", reported), ["mali", "KMSDRM"])
        self.assertEqual(video_drivers("brick", ["dummy", "offscreen", "x11"]), [])

    def test_use_arm64_libraries_even_when_32_bit_or_stub_is_first(self):
        with tempfile.TemporaryDirectory() as tmp:
            dirs = [Path(tmp)/d for d in ("invalid", "arm32", "valid")]
            for p in dirs:
                p.mkdir()
            name = "libSDL2.so"
            (dirs[0]/name).write_text("not a library")
            for p, width, machine in [(dirs[1], 1, 40), (dirs[2], 2, 183)]:
                data = bytearray(64)
                data[:6] = b"\x7fELF" + bytes((width, 1))
                data[16:20] = (3).to_bytes(2, "little")+machine.to_bytes(2, "little")
                (p/name).write_bytes(data)
            self.assertEqual(library_candidates(dirs, (name,)), [dirs[2]/name])


if __name__ == "__main__":
    unittest.main()
