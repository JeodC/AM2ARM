// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 25;
global.mapoffsety = 21;
global.waterlevel = 0;
global.floormaterial = 1;
// Keep these destroyed blocks from regenerating during this room visit.
with (oBlockSpeed) regentime = -1;
with (oBlockSMissile) regentime = -1;

// Create the pickups selected by this game's item mapping.
instance_create(72, 144, scr_itemsopen(oControl.mod_162));