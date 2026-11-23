AM2ARM 1.6.3 for ARM64 Linux

1. Extract the Linux launcher ZIP on your computer. If extraction creates
   a folder named AM2ARM-Autopatcher-1.6.3-linux-arm64, open it. You should
   see am2arm-launcher, ports, Tools, Apps and App together.
2. Using a card reader or USB file transfer, copy everything inside to the
   destination for your firmware. Merge the folders if prompted.

   On ROCKNIX, open games-internal/roms on the system card, roms on a
   separate games card, or the games-roms network share.
   On AmberELEC, let the handheld finish its first boot, then open GAMES.
   On NextUI, stock TrimUI and spruceOS, open the top level of the game card.
   On other supported Ports firmware, open the ROM library containing ports.

3. Put your original Windows AM2R_11.zip beside am2arm-launcher. Keep it
   zipped and allow 3 GB of free space after copying.
4. Open AM2ARM in Ports on ROCKNIX and other supported Ports firmware,
   Tools on NextUI, or Apps on stock TrimUI and spruceOS. The first launch
   installs and starts the game. Open the same entry next time to play.

Standard starts automatically on recognized single-screen devices. With two
screens, choose Standard or Dual Screen once. AM2ARM Editions in Ports lets
you change your choice later. If the installer asks for the original ZIP,
select it with the D-pad and A. This also works with a renamed backup.

On a single-screen handheld, Standard fits the picture to your screen.
To choose another aspect ratio, open Options > Display. To exit to the
handheld menu, save at a station and hold Start + Select for one second.
On a Smart Pro S with spruceOS, the Menu button also works if its tap or
hold action is set to Exit game in the firmware.

The launcher runs directly from your handheld menu. A fresh TrimUI Brick on
NextUI or stock and some other displays need Westonpack. AM2ARM uses a
verified copy already on the card, or downloads and verifies it once
(53 MiB). To prepare an offline card for one of these devices, download the
file below on your computer and put weston_pkg_0.2.squashfs beside AM2R_11.zip.
Keep both files intact. Wayland and native KMS displays can install offline
with the original game ZIP alone. Gameplay works offline on all supported
displays.

https://github.com/PortsMaster/PortMaster-New/releases/download/2025-07-24_0745/weston_pkg_0.2.squashfs

On ROCKNIX, check these paths from the ROM library if the entry is missing.
  AM2R_11.zip
  am2arm-launcher/launch.sh
  ports/AM2ARM.sh
Then open Start > Game Settings > Update Gamelists. On Ports firmware with a
capital Roms directory, open Roms as the destination before copying.

Already playing? A complete installation of the same version in a recognized
location opens directly. A different version is installed alongside it. Back
up saves through Options > Data before changing versions. The launcher stores
new games and your edition choice in AM2ARM-data. Keep your original ZIP.

For help with a supported ARM64 handheld, include your model, firmware and
am2arm-launcher/AM2ARM/logs/compatibility.txt. On direct-display firmware the same
logs folder contains the installer and game logs.
https://github.com/PatchDev-AM2ARM/AM2ARM

Thanks to Jeod for suggesting first-launch patching and sharing the LADXHD
and AM2R PortMaster launchers as references.
https://github.com/JeodC/RHH-Ports/tree/main/ports/released/zelda-ladxhd
https://github.com/JeodC/RHH-Ports/tree/main/ports/released/gamemakerengine/am2r
