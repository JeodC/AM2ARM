# AM2ARM Launcher for ARM64 Linux

Open **AM2ARM** from the handheld menu to install or play Standard or Dual Screen. The launcher uses the original Windows AM2R 1.1 ZIP supplied by the player. Both editions are available from the same menu. The firmware determines which display outputs the game can use. [Player setup and firmware paths](../../README.md#install-on-linux)

## Build the launcher ZIP

The build uses Python 3.11 or newer, Pillow, GNU binutils (`ar` and `readelf`) and SquashFS tools (`mksquashfs` and `unsquashfs`). Beta 1 artwork was generated with Pillow 13.0.0. A player supplies the original game ZIP on the handheld.

| Build input | SHA-256 |
| --- | --- |
| [AM2ARM 1.6.3 Linux Autopatcher](https://github.com/PatchDev-AM2ARM/AM2ARM/releases/download/v1.6.3/AM2ARM-Autopatcher-1.6.3-linux-arm64.zip) | `4c3661d8fbbfe236ef550a8816ee5199ced7034df2b1d8f5584f3bd09b4ea5c1` |
| [Westonpack 0.2.7.1 ARM64 runtime](https://github.com/PortsMaster/PortMaster-New/releases/download/2025-07-24_0745/weston_pkg_0.2.squashfs) | `0bccaeebc11296bb1fe4278c9677cb82965c5a04bcd63745fa09d78228bc1a93` |

The third input is the dArkOS audio bundle, SHA-256 `5a4bb8aa26ac6fa6793e42726e8e924b32f633be4ded3953dcd1a8d66ee99c3f`. The helper can download the pinned Debian packages once. With those files cached, the build works offline. Run from the repository root.

```sh
cd launcher/linux
export AM2ARM_BASE_ZIP="$HOME/Downloads/AM2ARM-Autopatcher-1.6.3-linux-arm64.zip"
export AM2ARM_WESTONPACK="$HOME/Downloads/weston_pkg_0.2.squashfs"
export AM2ARM_LAUNCHER_ZIP="$PWD/AM2ARM-Launcher-1.6.3-beta.1-linux-arm64.zip"
export AM2ARM_DARKOS_AUDIO="$PWD/darkos-audio-arm64.zip"
python3 -B darkos_audio_bundle.py --fetch "$PWD/debian-inputs" "$AM2ARM_DARKOS_AUDIO"
python3 -B build_launcher.py "$AM2ARM_BASE_ZIP" "$AM2ARM_LAUNCHER_ZIP" --westonpack "$AM2ARM_WESTONPACK" --darkos-audio "$AM2ARM_DARKOS_AUDIO"
```

The builder checks the inputs, reads the two display libraries from the verified runtime and reuses the published patches for both games. It also builds the read-only runtime used on the KNULLI Brick. A failed build preserves an existing output ZIP. [Dependency inventory, upstream contributions and notices](../../native/unified/menus/dependencies/README.md)

## Run the checks

Use the same environment variables after building. The tests use Python’s Tk module, Pillow and an X display. For the previous-thumbnail migration check, place the companion `am2arm.zip` from the v1.6.3 release beside the base ZIP. A headless Linux host can use Xvfb and xauth. [Previous thumbnail fixture](https://github.com/PatchDev-AM2ARM/AM2ARM/releases/download/v1.6.3/am2arm.zip)

```sh
xvfb-run -a python3 -B -m unittest discover -v
```

The checks cover controller navigation, install and play labels, direct relaunch, edition switching, original ZIP discovery, Ports artwork, firmware display and audio routes, bundled libraries, notices and the KNULLI image. Hardware reports are listed separately in the [compatibility table](../../README.md#compatibility).

## Source layout

- `launcher/first_run_gui.py` and `launcher/first_run.py` implement the edition menu, original ZIP discovery and recognition of older menu entries.
- `launcher/route.py` and `launcher/session.sh` select a firmware display session and start the game. `launcher/trimui_device.py` contains the Brick controller mappings.
- `launcher/weston_graphics.py` verifies the local Brick display libraries. `launcher/knulli_card.sh` mounts the read-only tools when KNULLI uses exFAT through FUSE.
- The Linux patcher verifies and reconstructs the game. Its source, the game projects and Project Restore Tool instructions are in the [development guide](../../docs/README.md).
