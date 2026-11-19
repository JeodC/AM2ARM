// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 51;
global.mapoffsety = 29;
global.watertype = 0;
global.waterlevel = 0;
global.floormaterial = 1;
// Schedule the environment scan if its log state permits it.
scan_log(25, get_text("ScanEvents", "ScanEnvironment"), 180, 0);