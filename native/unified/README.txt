AM2ARM Linux handheld launchers

The ARM64 installer and its patch data live in AM2ARM/patcher on the game card.
AM2ARM/launch.sh and the Python modules and scripts in runtime/ select the
firmware display session. menu_entries.py creates the menu shortcuts. All
shortcuts share the same installer. The selected edition is reconstructed
from the player's original Windows AM2R 1.1 ZIP.

Supported Ports systems use their existing Wayland session. For the supported
direct-display handhelds, the installer uses the firmware's SDL2 video driver.
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

Assembling a card ZIP

Extract the current Linux release to a temporary directory. It provides the
ARM64 runtime, installer assets and decoder. Use a fresh extracted copy without
saves or logs. Replace the patcher's edition patches with your own generated
patches as needed. package_sd.py combines the patcher, runtime, menu launchers
and source files from this directory into one card ZIP. Run from the repo root:

  python3 native/unified/package_sd.py <extract>/AM2ARM/patcher \
    <extract>/AM2ARM <output.zip>

To build app-local components from source, see dependencies/README.txt and the
native build instructions above. Supply the resulting binaries in the same
runtime layout. Original game assets are reconstructed from the player's ZIP.
