// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 58;
global.mapoffsety = 7;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 3;
// Schedule the environment scan if its log state permits it.
scan_log(21, get_text("ScanEvents", "ScanEnvironment"), 120, 0);
// Choose the outdoor backgrounds and ship appearance for the saved time of day.
load_timeofday_bgs(global.timeofday);

// Create the pickups selected by this game's item mapping.
instance_create(1944, 160, scr_itemsopen(oControl.mod_109));