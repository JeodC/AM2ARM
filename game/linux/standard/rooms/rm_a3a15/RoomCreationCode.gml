// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 66;
global.mapoffsety = 25;
global.watertype = 0;
global.waterlevel = 0;
global.floormaterial = 4;
// Run moving-solid carry and collision handling in the player's movement update.
global.movingobj = 1;

// Create the pickups selected by this game's item mapping.
instance_create(72, 80, scr_itemsopen(oControl.mod_201));