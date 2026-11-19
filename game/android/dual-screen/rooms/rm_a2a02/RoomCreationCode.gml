// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 33;
global.mapoffsety = 21;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 4;

// Schedule the environment scan if its log state permits it.
scan_log(23, get_text("ScanEvents", "ScanEnvironment"), 180, 0); // Don't delete.