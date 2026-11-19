// Offset this room's local map cells into the world map.
global.mapoffsetx = 67;
global.mapoffsety = 51;
// Treat the whole room as underwater, with the water surface above the room.
make_deep_water();
// Set the default material inherited by solids for footstep sounds.
global.floormaterial = 4;

// Create the pickups selected by this game's item mapping.
instance_create(32, 352, scr_itemsopen(oControl.mod_305));