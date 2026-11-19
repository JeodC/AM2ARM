// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 44;
global.mapoffsety = 40;
global.watertype = 0;
global.waterlevel = 0;
global.floormaterial = 1;
// Restore lava only while the saved drainage stage leaves this room flooded.
if (global.lavastate <= 6) make_liquid(1, 424, 0, 0, 0, 0, 0);
// Keep these destroyed blocks from regenerating during this room visit.
with (oBlockSpeed) regentime = -1;

// Create the pickups selected by this game's item mapping.
instance_create(560, 448, scr_itemsopen(oControl.mod_55));