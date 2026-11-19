// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 44;
global.mapoffsety = 28;
global.watertype = 0;
global.waterlevel = 0;
global.floormaterial = 1;

// Create the pickups selected by this game's item mapping.
instance_create(80, 432, scr_itemsopen(oControl.mod_54));