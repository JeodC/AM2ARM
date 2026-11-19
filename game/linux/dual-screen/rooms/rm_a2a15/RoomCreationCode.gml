// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 35;
global.mapoffsety = 24;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 4;

// Create the pickups selected by this game's item mapping.
instance_create(552, 64, scr_itemsopen(oControl.mod_153));
instance_create(280, 192, scr_itemsopen(oControl.mod_154));