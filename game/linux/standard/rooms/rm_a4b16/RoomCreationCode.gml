// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 36;
global.mapoffsety = 58;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 4;
// Schedule the environment scan if its log state permits it.
scan_log(27, get_text("ScanEvents", "ScanEnvironment"), 120, 0);
// Enable shaking and explosions while the escape sequence is active.
make_escape_sequence_fx(2);

// Create the pickups selected by this game's item mapping.
instance_create(528, 176, scr_itemsopen(oControl.mod_253));