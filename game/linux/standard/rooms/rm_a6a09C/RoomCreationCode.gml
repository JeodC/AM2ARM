// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 27;
global.mapoffsety = 47;
global.waterlevel = 0;
global.floormaterial = 1;
// Skip blanket deactivation of solids and enemies; view-region activation still runs.
global.objdeactivate = 0;
// Schedule the environment scan if its log state permits it.
scan_log(5, get_text("ScanEvents", "ScanEnvironment"), 180, 1);

// Create the pickups selected by this game's item mapping.
instance_create(544, 208, scr_itemsopen(oControl.mod_51));