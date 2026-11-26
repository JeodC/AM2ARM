# AM2ARM

Rebuild AM2R for **ARM64 Android or Linux** from your own original Windows
**AM2R 1.1 ZIP**. Standard plays on one screen. Dual Screen puts gameplay above
the interactive map on supported two-screen devices.

AM2ARM is based on **AM2R Community Updates 1.5.5**. The title screen displays
**V1.6.3** on Linux and **V1.6.2** on Android.

## Downloads

| Platform | Download |
| --- | --- |
| ARM64 Linux handhelds | [AM2ARM Launcher 1.6.3 · Beta 1 (ZIP)](https://github.com/PatchDev-AM2ARM/AM2ARM/releases/download/v1.6.3/AM2ARM-Launcher-1.6.3-beta.1-linux-arm64.zip) |
| ARM64 Android | [AM2ARM Autopatcher 1.6.2 (APK)](https://github.com/PatchDev-AM2ARM/AM2ARM/releases/download/v1.6.2/AM2ARM-Autopatcher-1.6.2.apk) |

Both downloads rebuild the selected edition locally from your own original Windows AM2R 1.1 ZIP. Linux setup works offline with physical buttons. The Dual Screen map uses touch. [Linux install instructions](#install-on-linux) · [Android install instructions](#install-on-android) · [All releases](https://github.com/PatchDev-AM2ARM/AM2ARM/releases)

## What's new in the Linux launcher beta

- Open **AM2ARM** from the handheld menu to install, play or switch editions. Choose **Standard** or **Dual Screen** on first launch. Next time the last edition starts automatically. Hold **D-pad Up** while opening AM2ARM to switch.
- Put your original ZIP in **AM2ARM/** on every supported firmware. The launcher opens a file picker if it needs help finding a valid copy.
- Standard supports the BATLEXP G350 on dArkOS and the TrimUI Brick on muOS. Brick display support is included for offline setup.

The launcher installs the 1.6.3 game. See the [Linux prerelease notes](https://github.com/PatchDev-AM2ARM/AM2ARM/releases/tag/v1.6.3).

## Install on Android

The Autopatcher requires **Android 10 or newer on an ARM64 device**.

1. Put your original `AM2R_11.zip` in Downloads or another folder the system
   file picker can access.
2. Install **AM2ARM Autopatcher**. Allow installation from your browser or
   file manager when Android asks.
3. Open it, select **Standard** or **Dual Screen**, then select your ZIP.
   Wait for reconstruction and verification.
4. The generated game APK is saved in **Downloads**. Choose **Install Standard**
   or **Install Dual Screen**, allowing the patcher to install it when asked.
5. Open **AM2ARM** or **AM2ARM DS** directly. The game no longer needs the
   Autopatcher to run. Dual Screen asks for a hardware profile on first boot.

For **Retroid Pocket Nova + Dual Screen Add-on**, select the **Retroid Pocket
Duo / Duo Lite** profile and enable **Dual Screen Add-on**. Leave that option
off on ordinary Duo/Duo Lite devices. RG DS has its own screen-order option;
use the order that places gameplay above the map.

To update, back up your saves, install the new Autopatcher, reconstruct the
edition you use and install its generated APK over the existing game. Updating
only the patcher does not update the game. **Do not uninstall the old game**:
uninstalling deletes its private saves. Package IDs and signing are preserved.

## Install on Linux

You need the **AM2ARM Launcher ZIP**, your own original **Windows AM2R 1.1 ZIP**, and **3 GB free** on the game card after copying.

1. Extract the **launcher ZIP** on your computer. Open the folder containing `AM2ARM-READ-ME.txt`. Inside it, place your **still-zipped game** in `AM2ARM/`. For example, `AM2ARM/AM2R_11.zip` works on every supported firmware.
2. Copy the **contents of the folder containing the readme** into the game library below. Merge the folders when prompted. Use a card reader or [USB file transfer](#usb-transfer-without-removing-the-card). On a two-card handheld, use the games card.
3. Open **AM2ARM** from the handheld menu. Use the D-pad to highlight an edition and press **A**. **Install** checks your ZIP, installs the edition and starts it on a supported display. **Play** opens a complete edition already on the card. If the picker opens, select your original with **A** or press **B** to return.
4. Next time, open **AM2ARM** to go straight into the last edition you played. To switch editions, hold **D-pad Up** as the launcher opens. Removing `AM2ARM-data/edition.txt` also reopens the menu. Keep your original ZIP for repairs or to add the other edition.

| Firmware | Copy the extracted contents here | Open AM2ARM from |
| --- | --- | --- |
| Stock Anbernic RG DS Linux | Top of **ROMS**, after the first boot | Ports |
| ROCKNIX | `games-internal/roms` on the system card, `roms` on a separate games card, or the `games-roms` network share | Ports |
| AmberELEC | Top of **GAMES**, after the first boot | Ports |
| dArkOS (BATLEXP G350) | Top of **EASYROMS**, after first boot | Ports |
| muOS (TrimUI Brick) | Top of the games card after **Install** | Explore Content → Ports |
| KNULLI | **SHARE** → `roms`, after the first boot | Ports |
| NextUI | Top of the games card, alongside `Tools` | Tools |
| Stock TrimUI or spruceOS | Top of the games card | Apps |

On the tested muOS exFAT card, copying the archive contents is sufficient. On a case-sensitive ext4 card, copy `roms/ports/AM2ARM.sh` into `ROMS/Ports/`.

For example, the KNULLI card should contain `SHARE/roms/AM2ARM/AM2R_11.zip` and `SHARE/roms/ports/AM2ARM.sh`. On ROCKNIX, check that `ports/AM2ARM.sh` and `am2arm-launcher/launch.sh` are in the same game library. Refresh **Start → Game Settings → Update Gamelists** if the entry is missing.

**Standard** uses one screen. **Dual Screen** needs two usable outputs and touch for the map. A single-output display driver offers **Install Dual Screen** for use on another setup. Choose **Standard** to install and play locally.

### USB transfer without removing the card

USB access depends on both the handheld and its firmware. An **OTG label alone
does not guarantee PC file transfer**. Use a data cable and the correct data
port; copying uses the same folders as a card reader.

- **ROCKNIX:** open Network Settings, enable Samba or SSH, choose USB Gadget
  Function **Network**, then exit settings to apply it. Connect by USB and
  access the `games-roms` share or use SFTP at the address shown by the device.
  This needs no Wi-Fi. **File Transfer** is another option where supported.
  See the [ROCKNIX transfer guide](https://rocknix.org/play/add-games/).
- **NextUI:** [NextUI Dashboard](https://dashboard.loveretro.games/) provides
  browser-based USB/ADB uploads in Chrome or Edge. Connect the powered-on Brick,
  select it in the browser's connection prompt, then use **File Browser** to
  upload the extracted folders under `/mnt/SDCARD/`, preserving their paths.
  The original game ZIP stays zipped. The Brick needs no Wi-Fi; the PC needs
  access to the Dashboard website. See its [instructions](https://github.com/aaronhoogstraten/nextui-web-dashboard).
- **Other firmware:** use its documented USB file-transfer mode. If it supports
  an external USB drive through OTG and has a file manager, copying from that
  drive to the card is another route. Otherwise use a card reader.

On the **G350**, USB networking was verified with **ROCKNIX**.

### Updates and startup problems

Back up your saves through **Options → Data**. Copy the new launcher into the same game library and merge its folders. Open **AM2ARM**. It reuses complete matching 1.6.3 installations in recognized locations. Hold **D-pad Up** during launch to select an edition again. New installations and the selected edition live in `AM2ARM-data/`. Keep that folder and your existing game and save folders when updating.

For startup problems, include your handheld, firmware version, edition, and the last screen you saw. The launcher log on the game card is `am2arm-launcher/AM2ARM/logs/compatibility.txt`. Review it for personal paths before sharing. Keep your original game ZIP and saves private. [Report a problem](https://github.com/PatchDev-AM2ARM/AM2ARM/issues)

## Compatibility

Beta 1 was checked on a physical G350 with dArkOS and a physical Brick with muOS. The checks covered discovery of the original ZIP, Standard installation, picture, sound, controls and direct relaunch. The other rows describe earlier launcher or game checks on the listed firmware.

| Platform | Device / setup | Verified scope |
| --- | --- | --- |
| Android | AYN Thor | Standard and Dual Screen |
| Android | AYANEO Pocket DS; Retroid Pocket Duo and Duo Lite | Community-tested Dual Screen |
| Android | Original RG DS, stock Android / GammaOS | Dual Screen; demanding scenes can slow down |
| Android | Retroid Pocket Nova + Retroid Dual Screen Add-on | Community-tested with the Retroid profile |
| Linux | Original RG DS, stock Linux 1.1-261008 | Fresh installation, Standard and Dual Screen, controls, sound, touch and Standard vibration |
| Linux | RG DS, ROCKNIX 20261101 | Installer and Standard; Dual Screen on this firmware unverified |
| Linux | BATLEXP G350, ROCKNIX | Installer, Standard, save transfer and aspect-ratio checks |
| Linux | BATLEXP G350, dArkOS v11172026 | Beta 1, fresh offline Standard installation and direct relaunch from Ports |
| Linux | BATLEXP G350, AmberELEC RG351MP prerelease 20261019_1835 | Earlier launcher, automatic ZIP detection, Standard installation, controls and relaunch from Ports |
| Linux | TrimUI Brick, KNULLI | Standard first install, title music, printed face and shoulder buttons, exit to Ports and relaunch during launcher development |
| Linux | TrimUI Brick, muOS 2606.0 Andromeda (exFAT) | Beta 1, fresh offline Standard installation and direct relaunch from Explore Content → Ports |
| Linux | TrimUI Brick, NextUI v6.15.0 | Earlier launcher, automatic ZIP detection, Standard installation, controls and relaunch from Tools |
| Linux | TrimUI Brick, stock menu 1.0.6 | Fresh-card installation, fullscreen gameplay, music, controls and damage vibration |
| Linux | Miyoo Flip V2, RK3566 / MY355, BaseOS 1.3.0 | Standard confirmed by a community tester |

**TrimUI Smart Pro S** uses a separate TG5050 profile. Standard gameplay was
reported on spruceOS at 3× and 16:9. The latest display and exit changes
await a hardware check. The **original Smart Pro** has a separate TG5040 profile and also awaits hardware
confirmation. Brick Pro and the 32-bit Miyoo Mini Flip use different hardware.

The stock Brick check used the stock menu on a Brick with a CrossMix 1.3.9
marker. Damage vibration was verified there. A physical NextUI vibration check
is still pending. Previous RG DS, G350 and Brick checks are listed above for
their tested firmware and features.

Supported Ports firmware can use an existing Wayland session. The supported
direct-display profiles use the handheld's own graphics libraries. Keep the
device's graphics drivers and firmware in place. Stock G350 BATLEXPOS is
outside the supported setups in this release. R36S, RG DS Plus and newer
ARM64 RG35XX variants still need their own firmware checks. The original
Cortex-A9 RG35XX runs 32-bit ARM and cannot run this ARM64 package.
On AmberELEC, the G350 and RG351P can select the firmware's KMSDRM display
when Wayland is unavailable. The RG351P firmware libraries were checked on
prerelease 20261019_1835. A physical RG351P run is still pending.
KNULLI on the Brick also supports the firmware’s direct display. G350 on KNULLI still needs a separate hardware check.

## Controls and display

**Standard** provides gameplay on a single screen. Android supports touch and
controllers; Linux uses physical controls. Aspect Ratio offers **4:3 / 16:9 /
3:2** without stretching. During play, a change applies at the next room transition.

On supported single-screen Linux handhelds, Standard picks the best-fitting
aspect ratio on first launch. You can still choose another ratio in Display
Options. The handheld already fills its panel, so the desktop Fullscreen
switch is hidden. To exit to the handheld menu, save at a station and hold
**Start + Select** together for one second. On a Smart Pro S running spruceOS,
you can also use the physical Menu button if its tap or hold action is set to
**Exit game** in the firmware.

Android Standard's **Touch Control Scale**, **Control Spacing** and **Diagonal
Aim Size** are independent. Enlarging diagonal arrows shrinks the joystick
inside the same overall area, and the touch targets follow the graphics.

**Dual Screen** puts gameplay above and the map/HUD below. Map buttons,
dragging and pinch zoom use touch; Samus uses the controller. **HUD Screen
Position** can move health and ammunition to the gameplay screen. A single
foldable/tablet canvas split into two panels is not supported.

**Nano**, in Display Options, reduces selected decorative effects to help
slower hardware. It is optional and does not guarantee 60 FPS everywhere.
Android launchers running behind the lower display, including some Cocoon
setups, can affect performance.
The lower screen may take a moment to resume after switching apps.

## Saves and transfer

Use **Options → Data → Back Up Saves** to create a portable backup. Copy that
entire folder to the other device, then choose **Data → Restore Saves** from
the title/file-selection options. This works with Android exports and PC
Community Updates 1.5.5 saves. Restore is unavailable during active gameplay.
Choose the source and destination slot; unlock records are a separate choice.

Android uses its system folder picker. Linux uses a controller-operated picker:
Confirm opens a folder, Back cancels, Left/Right move by a page, and **USE THIS
FOLDER** selects it. Backup creates a new folder instead of replacing an old
one. Restore validates files and keeps replaced progress in `pre-restore-backup`.

Keep the filenames `save1`, `save2`, `save3`, `data.sav` and `extras.sav`.
**Do not copy portable exports directly over raw Linux saves**; use Restore.
Ports keeps raw saves in `state/config/AM2RStandardLinux/` or
`state/config/AM2RDualLinux/` inside the installed game. Stock TrimUI uses the
game's state directory and keeps its previous save location on an update.
NextUI uses the firmware's home directory, usually
`.userdata/tg5040/.config/AM2RStandardLinux/` on Brick. On spruceOS and
direct-display Ports, new installations use
`AM2ARM-data/home/.config/AM2RStandardLinux/`. Upgrades reuse an existing
`AM2ARM/state/home/.config/AM2RStandardLinux/` when present. Close the game before copying
raw state and keep `config.ini` separate between platforms.

### Android folder synchronization

Choose **Data → Sync Folder** in each Android edition and synchronize that
folder with your own file-sync app. Wait for transfers before switching devices.
AM2ARM exports completed saves and checks incoming progress at file selection;
**Sync Now** checks on demand. It does not sign into a cloud account or perform
network transfers itself. Linux uses manual Backup/Restore, not automatic sync.

Keep the `am2r-sync-*.zip` files and `AM2R-Sync-Recovery` folder together. Do not
rename or merge their contents. Conflicts are held for **Review Sync Conflict**
at the title menu; missing shared slots do not delete local progress. **Disable
Sync** leaves saves intact. Use separate folders for independent playthroughs.
The desktop game does not read these sync ZIPs; use portable backups with it.

## Development

The repository contains the Standard and Dual Screen GameMaker projects for
Android and Linux, the Android Autopatcher, the Linux launcher and patcher source, and the native Linux integration.
Original media and signing material are omitted. Use your own original AM2R
1.1 ZIP to restore the missing inputs locally. The development guide lists
the matching restore files, toolchain and build steps. [Development guide](docs/README.md)

## Support and credits

[Report a problem](https://github.com/PatchDev-AM2ARM/AM2ARM/issues) with the exact
model, firmware/OS, edition, Nano setting and steps to reproduce it. For Linux
startup failures include `compatibility.txt` and relevant state logs. Review logs
for personal paths before sharing. Do not attach the original ZIP or a complete
game package. Reports from stronger devices also help with compatibility.

Thanks to Jeod for sharing the LADXHD and AM2R first-launch examples, and to BinaryCounter and the GL4ES contributors for the display libraries used on the Brick. [LADXHD](https://github.com/JeodC/RHH-Ports/tree/main/ports/released/zelda-ladxhd) · [AM2R launch example](https://github.com/JeodC/RHH-Ports/tree/main/ports/released/gamemakerengine/am2r) · [Runtime credits](native/unified/menus/dependencies/README.md)

AM2R and Community Updates retain their original credits. This is a community
port, not a Nintendo release. [LICENSE](LICENSE) covers the patcher code;
game source and dependencies retain their respective notices and licenses.
The patcher's MIT license does not relicense original game material.
