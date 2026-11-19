// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 69;
global.mapoffsety = 39;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 4;

// Create the pickups selected by this game's item mapping.
instance_create(472, 224, scr_itemsopen(oControl.mod_308));