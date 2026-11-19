// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 10;
global.mapoffsety = 20;
global.waterlevel = 0;
global.floormaterial = 3;
// Schedule the environment scan if its log state permits it.
scan_log(29, get_text("ScanEvents", "ScanEnvironment"), 120, 0);