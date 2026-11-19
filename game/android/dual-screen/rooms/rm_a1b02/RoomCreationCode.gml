// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 58;
global.mapoffsety = 14;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 5;
// Schedule the environment scan if its log state permits it.
scan_log(22, get_text("ScanEvents", "ScanEnvironment"), 180, 0);