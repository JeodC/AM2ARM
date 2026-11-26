# Building from the 1.6.3 source

Get the repository at tag **v1.6.3-launcher-beta.1** or download the [matching launcher source ZIP](https://github.com/PatchDev-AM2ARM/AM2ARM/archive/refs/tags/v1.6.3-launcher-beta.1.zip). Both contain the editable projects for this launcher. For the ZIP, extract it and open the directory containing `game`, `autopatcher` and `restoration`. The commands below run from that directory. This tag builds Linux 1.6.3 and Android 1.6.2.

| Project | Folder | Entry point |
| --- | --- | --- |
| Android Standard | `game/android/standard` | `AM2R-project.yyp` |
| Android Dual Screen | `game/android/dual-screen` | `AM2R-project.yyp` |
| Linux Standard | `game/linux/standard` | `AM2RStandardLinux.yyp` |
| Linux Dual Screen | `game/linux/dual-screen` | `AM2RDualLinux.yyp` |
| Android Autopatcher | `autopatcher/android` | `app-android` for the app, `am2r_android_patcher.py` for the PC utility |
| Linux Launcher | [`launcher/linux`](../launcher/linux/README.md) | `build_launcher.py` for the handheld download |
| Linux patcher core and utilities | `autopatcher/linux` | `handheld_launch.py` for handhelds, `linux_patcher.py` for desktop use |

The standalone Linux launcher packages the published game patches. It builds from the published 1.6.3 Linux package, two verified Westonpack libraries and a reproducible audio bundle from pinned Debian ARM64 packages. [Build and test the Linux launcher](../launcher/linux/README.md)

## Restore the missing project inputs

Install Python 3.11 or newer and xdelta3 on your development computer. Keep your own original Windows `AM2R_11.zip` and the **AM2ARM-Source-Restore-1.6.1.zip** download. The 1.6.3 catalog is in this checkout. It reuses the same binary patches as 1.6.1. Place the checkout on a filesystem that supports hard links, such as NTFS or ext4. Once you have those inputs, the following commands work offline. [Download the matching patch pack from v1.6.1](https://github.com/PatchDev-AM2ARM/AM2ARM/releases/download/v1.6.1/AM2ARM-Source-Restore-1.6.1.zip).

1. Prepare the bundle once. Pass the downloaded ZIP itself.

   ```sh
   python3 restoration/prepare_bundle.py "/path/to/AM2ARM-Source-Restore-1.6.1.zip"
   ```

   The helper verifies the whole ZIP's SHA-256, extracts the two verified patch sets, and builds the Project Restore Tool catalog for all six folders under `restoration/bundle`. Keep the complete checkout together for this step.
2. Restore and check the project you plan to edit. Choose one of the four game projects or two Autopatcher projects listed above.

   ```sh
   python3 restoration/restore_project.py --project game/android/standard --zip "/path/to/AM2R_11.zip"
   python3 restoration/restore_project.py --project game/android/standard --check
   ```

   On Windows, use `py -3` in place of `python3`. PRT verifies the donor and every restored file. It preserves source edits, reports changes to a reference source file, and stops if existing media has different bytes. Keep each `asset-inputs.json` unchanged. To prepare the bundle elsewhere, pass `--output "/path/to/bundle"` to the first command and `--bundle "/path/to/bundle"` to both PRT commands.
3. Open the entry point for the selected project. Game projects use GameMaker Beta IDE 2026.100.0.1083 and runtime 2026.100.0.1046. Read that project's `BUILDING.txt` for its licensed toolchain and native inputs.

The report lists missing generated inputs separately. Linux builds need the haptics and save-transfer libraries. Dual Screen also needs the display extension. Build these from the matching source. The two Autopatchers restore interface media and require edition patch bundles from your privately built games. Android updates require the original signing identity. Use your own package ID and key for independent builds. [Native build instructions](../native/linux/BUILDING.txt) · [Android patcher build](../autopatcher/android/README.md) · [Linux patcher build](../autopatcher/linux/README.txt).

## Native and dependency sources

The common Linux launcher, display extensions, patched GL4ES source and save-transfer helpers live in `native/linux`. The unified card layout and menu adapters live in `native/unified`. The TrimUI native rumble bridge is in `native/trimui`. The corresponding-source index lists the two base runtime archives from v1.6.1 and the Debian sources for dArkOS audio in this tag. [Runtime dependency sources](../dependencies/README.txt).

The game projects carry their own source terms in `LICENSE.txt` and `THIRD-PARTY.txt`. Autopatcher and PRT tooling and third-party components retain their respective notices. Keep restored media, saves, generated builds and signing material private. For a source contribution, include the affected platform and edition, the change, and the behavior you checked.
