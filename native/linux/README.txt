AM2ARM 1.6.3 - native ARM64 Linux integration

This package supplies the matching native launcher/display source and GL4ES
changes for AM2ARM Standard and Dual Screen on compatible ARM64 Wayland firmware.
The Linux game projects are in game/linux in this repository. Follow
docs/README.md to restore project media from your original AM2R 1.1 ZIP.
The menu scripts and direct-display adapters for the unified Linux package
are in native/unified.

BUILDING.txt describes the pinned native YYC arrangement. display/linux-display.c
and native-api.h build the omitted Dual Screen extension. Run, with an authorized
Debian 12 ARM64 development sysroot and Clang/LLD installed:

  SYSROOT=/path/to/arm64-sysroot sh display/build-display.sh /path/to/linux-dual/extensions/AM2RThor/libAM2RThor.so

The project's generated_inputs entry records the release library hash.
A locally built native library may differ with compiler versions and flags.
The source restore utility does not create or overwrite it.

Both Linux editions also use the vibration extension in rumble/. Build it with
the same sysroot, then copy it into the selected GameMaker project before build:

  SYSROOT=/path/to/arm64-sysroot sh rumble/build-rumble.sh /path/to/project/extensions/AM2RHaptics/libAM2ARMHaptics.so

Include libAM2ARMHaptics.so in the installed game data folder. It connects the
existing vibration values to a matching Linux force-feedback controller.

GL4ES revision, original archive hash and all local changes are supplied in
display/upstream.json and display/gl4es-wayland.patch. The patch includes the
Wayland protocol bindings. The pinned dependency sources also
provide the reviewed library source and upstream provenance.

runtime contains the actual matching launcher, focus and volume helpers,
controller mapping and save-location checks. Internal AM2RStandardLinux and
AM2RDualLinux save identities remain unchanged; displayed names are AM2ARM.
Do not package state folders, logs, restored media or complete private games.

Original notices remain in licenses. The GameMaker SDK, its proprietary engine
and system Mali drivers must be obtained separately under their original terms.
Read SOURCE-DEPENDENCIES.txt for exact third-party source access.
Repository: https://github.com/PatchDev-AM2ARM/AM2ARM

Both editions also require saves/build.py and libAM2ARMSaves.so. Read
saves/README.txt for the scoped backup/restore backend and build command.
