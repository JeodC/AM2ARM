// Set world-map placement and liquid state.
global.mapoffsetx = 47;
global.mapoffsety = 16;
global.waterlevel = 0;

// Create the pickups selected by this game's item mapping.
instance_create(288, 432, scr_itemsopen(oControl.mod_52));
instance_create(64, 64, scr_itemsopen(oControl.mod_53));