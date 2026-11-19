// Set world-map placement and liquid state.
global.mapoffsetx = 62;
global.mapoffsety = 12;
global.waterlevel = 0;
global.watertype = 0;

// Create the pickups selected by this game's item mapping.
instance_create(776, 128, scr_itemsopen(oControl.mod_103));