// Fit the transfer and optional sync controls inside the existing Data panel.
y -= 24;
var labels = [get_text("Misc", "BackupSaves"), get_text("Misc", "RestoreSaves"),
    port_caption("Sync Folder"), port_caption("Sync Now"), port_caption("Review Sync Conflict"), port_caption("Disable Sync"), get_text("GlobalOptions", "Exit")];
for (var n = 0; n <= lastitem; n++) {
    op[n] = instance_create(x, y + 16 * n, oPauseOption);
    op[n].optionid = n;
    op[n].label = labels[n];
}
op[1].enabled = !ingame;
op[3].enabled = global.am2r_sync.enabled;
op[4].enabled = global.am2r_sync.enabled && !ingame;
op[5].enabled = global.am2r_sync.enabled;
