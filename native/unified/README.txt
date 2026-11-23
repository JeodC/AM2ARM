AM2ARM Linux launcher

The standalone download contains one am2arm-launcher folder. Its Ports,
Apps and Tools shortcuts start the same launcher in auto mode. See
README-card.txt for the card instructions.

runtime/first_run.py locates an original Windows ZIP and checks installed
editions against the bundled release version. first_run_gui.py uses the
controller-enabled handheld installer. The existing patcher verifies the
original game data and the final archive. Both paths start the selected
game when preparation finishes. Older installations and their saves are
kept in place. New games live under AM2ARM-data/games/<version>.

On supported Ports systems, route.py checks the compositor with a Wayland
round trip. It passes the working socket to session.sh for both setup and play.
The game starts from its own launcher with the firmware's audio and controller
environment. On supported direct-display handhelds, the installer uses the
firmware's SDL2 video driver.
On the Miyoo Flip V2 and TrimUI Smart Pro S with KMSDRM, the Standard game uses
a GL4ES adapter backed by the firmware's SDL2 window and EGL context. The
firmware owns the hardware graphics libraries. See runtime/compat_display.py
for the board IDs, display sizes and SDL backends.

Building the KMSDRM adapter

Copy native/linux/gl4es from this repository into a separate build directory.
Apply the patch below to that copy; the Wayland adapter is already present.
Run from native/unified, setting GL4ES_SRC to the absolute path of the copy.

  patch -d "$GL4ES_SRC" -p1 < native/gl4es-kms.patch
  cp native/stock-sdl.c native/stock-sdl.h "$GL4ES_SRC/src/glx/"

Follow native/linux/BUILDING.txt for the ARM64 sysroot and compiler. Configure
with CMake using Release, DEFAULT_ES=2, NO_GBM=ON and CMAKE_SKIP_RPATH=ON.
Build GL, strip it with llvm-strip --strip-unneeded, and install libGL.so.1
in AM2ARM/runtime/kms. The Wayland adapter in the installed game and this
KMSDRM adapter have different entry points and stay in their own directories.
Upstream GL4ES license and source details are in native/linux.

Run the launcher tests from the repository root:

  PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=native/unified/runtime:autopatcher/linux \
    python3 -m unittest discover -s native/unified/tests

Assembling the launcher

For launcher-only changes, extract the verified standalone 1.6.3 ZIP. Use
its am2arm-launcher/AM2ARM directory as BASE and its patcher/patch-bundle
as the edition input. For a new game build, generate the edition patches
with make_patch_data.py.
Each new assembly.json records the size and SHA-256 of installed files.
From the repository root:

  python3 native/unified/package_sd.py "$BASE/patcher" "$BASE" \
    AM2ARM-Autopatcher-1.6.3-linux-arm64.zip --patcher-source autopatcher/linux \
    --patch-bundle "$BASE/patcher/patch-bundle" --version 1.6.3

See menus/dependencies/README.md for the included components, notices and
source archives. The standalone installer can also retrieve the pinned
Westonpack image from its upstream host. See README-card.txt for offline
placement. Firmware-menu shortcuts enable this first-launch download.
Only the player-supplied donor and the edition patch together reconstruct
a playable game.
