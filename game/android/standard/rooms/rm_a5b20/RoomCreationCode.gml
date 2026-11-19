// Offset this room's local map cells into the world map.
global.mapoffsetx = 57;
global.mapoffsety = 50;
// Treat the whole room as underwater, with the water surface above the room.
make_deep_water();
// Set the default material inherited by solids for footstep sounds.
global.floormaterial = 4;

// Create the pickups selected by this game's item mapping.
instance_create(816, 224, scr_itemsopen(oControl.mod_307));