// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 33;
global.mapoffsety = 33;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 3;

// Use item-room music when the optional music pack is available.
mus_change_itemroom();

// Apply the unpowered-room darkness while the facility power switch is still off.
if (global.event[200] == 0) global.darkness = 3;
// Schedule the environment scan if its log state permits it.
scan_log(26, get_text("ScanEvents", "ScanEnvironment"), 120, 0);