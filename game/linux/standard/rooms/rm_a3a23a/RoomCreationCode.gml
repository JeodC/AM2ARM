// Set world-map placement and the default footstep material.
global.mapoffsetx = 72;
global.mapoffsety = 32;
global.floormaterial = 1;

// Create the pickups selected by this game's item mapping.
instance_create(128, 160, scr_itemsopen(oControl.mod_206));