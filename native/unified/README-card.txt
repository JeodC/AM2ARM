AM2ARM 1.6.2 — Linux Autopatcher

You need an ARM64 handheld with supported firmware, your original Windows
AM2R_11.zip, and at least 3 GB free on the game card after copying the files.

1. Close the game. Use a card reader or the firmware's USB file-transfer mode.
   Extract this download on your computer. Keep your AM2R_11.zip zipped.
2. Copy the AM2ARM folder and the menu entry for your firmware.

   Ports (RG DS, G350 on ROCKNIX)
     Open your existing games/Ports directory. Copy AM2ARM there along with
     AM2ARM Autopatcher.sh from the download's ports folder. Both belong at
     the same level. On ROCKNIX the Ports folder is usually roms/ports or
     games-internal/roms/ports on the data partition.

   TrimUI stock Apps, NextUI Tools or spruceOS Apps
     Merge AM2ARM into the root of the game card. For stock TrimUI copy Apps
     there too. For NextUI copy Tools, and for spruceOS copy App (singular).
     Leave existing games and saves in place.

   Miyoo Flip V2, MY355 BaseOS
     Copy AM2ARM to the game-card root. Put the launcher from Roms/ports in
     the card's existing Roms/ports folder.

3. Put your own AM2R_11.zip in AM2ARM/patcher/input. Safely eject the card or
   finish USB transfer. Open AM2ARM Autopatcher in Ports, Apps or Tools.
4. Choose the ZIP and select INSTALL. The D-pad and confirm/back operate the
   installer. Direct-display handhelds install Standard. On dual-display
   supported Ports firmware you can select Dual Screen.
5. After INSTALLATION COMPLETE, exit and open AM2ARM Standard or AM2ARM Dual
   Screen. Refresh the list if needed. On ROCKNIX select Start, Game Settings,
   Update Gamelists.

Updating an existing game
Use Options > Data > Back Up Saves first. Keep your previous installation and
install into an empty destination. Restore through Options > Data if needed.
For Ports, the game and its matching .sh entry belong in the same directory.
A custom output directory must be visible to the handheld's game menu.

Troubleshooting
The card's AM2ARM/logs/compatibility.txt records the selected display route.
For Ports, also check AM2ARM/patcher/compatibility.txt and AM2ARM/patcher/state.
Send the model, firmware version and relevant logs if setup fails. Keep your
original ZIP, reconstructed game and saves private.

https://github.com/PatchDev-AM2ARM/AM2ARM
