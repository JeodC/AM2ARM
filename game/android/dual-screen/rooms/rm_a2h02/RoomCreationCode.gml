// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 29;
global.mapoffsety = 16;
global.waterlevel = 0;
global.floormaterial = 3;
// Disable the player's contact checks against upward and downward mover objects.
global.moverobj = 0;
// Restore the water-surface height selected by the saved turbine-drainage stage.
if (global.event[101] == 0) make_liquid(0, 1430, 1, 1, 0.05, 0.3, 1);
if (global.event[101] == 1) make_liquid(0, 1552, 1, 1, 0.05, 0.3, 1);
// Schedule the environment scan if its log state permits it.
scan_log(23, get_text("ScanEvents", "ScanEnvironment"), 180, 0);
// Allow the player's culling pass to deactivate solids and enemies before reactivating nearby instances.
global.objdeactivate = 1;

// Create the pickups selected by this game's item mapping.
instance_create(3144, 608, scr_itemsopen(oControl.mod_163));