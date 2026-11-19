// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 20;
global.mapoffsety = 22;
global.waterlevel = 0;
global.floormaterial = 5;

// Create the pickups selected by this game's item mapping.
instance_create(80, 160, scr_itemsopen(oControl.mod_160));
instance_create(448, 64, scr_itemsopen(oControl.mod_161));