// Offset this room's local map cells into the world map.
global.mapoffsetx = 63;
global.mapoffsety = 53;
// Treat the whole room as underwater, with the water surface above the room.
make_deep_water();
// Set the default material inherited by solids for footstep sounds.
global.floormaterial = 4;

// Create the pickups selected by this game's item mapping.
instance_create(672, 208, scr_itemsopen(oControl.mod_304));