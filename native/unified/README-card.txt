AM2ARM 1.6.3 for ARM64 Linux

1. Open the game library on your computer, with a card reader or USB file
   transfer. On ROCKNIX use games-internal/roms on the system card, roms on
   a separate games card, or the games-roms network share. On NextUI,
   stock TrimUI and spruceOS use the top level of the game card. Extract the
   contents of this ZIP directly there and merge folders when prompted.
2. Copy your original Windows AM2R_11.zip to that same location. Keep it zipped.
   Allow 3 GB of free space after copying the files.
3. Open AM2ARM on the handheld. Look in Tools on NextUI, Apps on TrimUI stock
   and spruceOS, or Ports on a system with a Ports menu. The first launch
   prepares the game and starts it. Open the same entry next time to play.

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

If the entry is missing, refresh the game list. On ROCKNIX, open Start >
Game Settings > Update Gamelists. On a case-sensitive card with a capital
Roms directory, extract the whole ZIP inside that directory for the Ports entry.

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
