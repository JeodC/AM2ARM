// Offset this room's local map cells into the world map.
global.mapoffsetx = 35;
global.mapoffsety = 53;
// Create the lava surface and its background and immersion effects.
make_liquid(1, 201, 0, 0, 0, 0, 0);
// Set the default material inherited by solids for footstep sounds.
global.floormaterial = 1;
// Keep these destroyed blocks from regenerating during this room visit.
with (oBlockSpeed) regentime = -1;

// Create the pickups selected by this game's item mapping.
instance_create(560, 208, scr_itemsopen(oControl.mod_56));