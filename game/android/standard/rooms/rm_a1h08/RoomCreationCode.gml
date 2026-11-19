// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 69;
global.mapoffsety = 12;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 3;

//mus_change_itemroom();

// Create the pickups selected by this game's item mapping.
instance_create(80, 432, scr_itemsopen(oControl.mod_spider));