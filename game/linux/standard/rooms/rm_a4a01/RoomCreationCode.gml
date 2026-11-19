// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 35;
global.mapoffsety = 39;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 4;
// Apply the unpowered-room darkness while the facility power switch is still off.
if (global.event[200] == 0) global.darkness = 3;
// Choose the room music from the saved facility power-switch state.
if (global.event[200] == 0) {
    mus_change(musCaveAmbienceA4);
} else mus_change(musArea4A);
// Schedule the environment scan if its log state permits it.
scan_log(26, get_text("ScanEvents", "ScanEnvironment"), 120, 0);