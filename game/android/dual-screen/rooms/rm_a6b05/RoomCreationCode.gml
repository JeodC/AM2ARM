// Set world-map placement, liquid state, the default footstep material, and ambient darkness.
global.mapoffsetx = 21;
global.mapoffsety = 29;
global.waterlevel = 0;
global.floormaterial = 5;
global.darkness = 4;
// Schedule the environment scan if its log state permits it.
scan_log(40, get_text("ScanEvents", "ScanEnvironment"), 120, 0);