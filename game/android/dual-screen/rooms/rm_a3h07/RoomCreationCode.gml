// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 67;
global.mapoffsety = 19;
global.watertype = 0;
global.waterlevel = 0;
global.floormaterial = 1;
// Keep these destroyed blocks from regenerating during this room visit.
with (oBlockPBomb) regentime = -1;
with (oBlockSpeed) regentime = -1;

// Create the pickups selected by this game's item mapping.
instance_create(560, 144, scr_itemsopen(oControl.mod_212));