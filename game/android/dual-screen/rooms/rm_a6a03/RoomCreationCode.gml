// Offset this room's local map cells into the world map.
global.mapoffsetx = 26;
global.mapoffsety = 53;
// Create the lava surface and its background and immersion effects.
make_liquid(1, 432, 0, 0, 0, 0, 0);
// Set the default material inherited by solids for footstep sounds.
global.floormaterial = 1;

// Create the pickups selected by this game's item mapping.
instance_create(1248, 432, scr_itemsopen(oControl.mod_60));