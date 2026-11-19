// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 50;
global.mapoffsety = 11;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 3;

// Create the pickups selected by this game's item mapping.
instance_create(96, 128, scr_itemsopen(oControl.mod_112));