// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 49;
global.mapoffsety = 20;
global.waterlevel = 0;
global.floormaterial = 1;

// Create the pickups selected by this game's item mapping.
instance_create(560, 112, scr_itemsopen(oControl.mod_57));