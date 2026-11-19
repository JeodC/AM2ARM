// Set world-map placement, liquid state, the default footstep material, and ambient darkness.
global.mapoffsetx = 50;
global.mapoffsety = 6;
global.floormaterial = 4;
global.waterlevel = 0;
global.darkness = 0;
//scan_log(6, get_text("ScanEvents", "ScanEnvironment"), 180, 1);

// Create the trooper-log trigger only while that log is still uncollected.
create_log_trigger(true, 2, 323, 208, -26, true);