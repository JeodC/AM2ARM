// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 70;
global.mapoffsety = 26;
global.watertype = 0;
global.waterlevel = 0;
global.floormaterial = 4;
// Run moving-solid carry and collision handling in the player's movement update.
global.movingobj = 1;

// Create the pickups selected by this game's item mapping.
instance_create(832, 64, scr_itemsopen(oControl.mod_205));