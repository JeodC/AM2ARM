// Offset this room's local map cells into the world map.
global.mapoffsetx = 57;
global.mapoffsety = 52;
// Treat the whole room as underwater, with the water surface above the room.
make_deep_water();
// Set the default material inherited by solids for footstep sounds.
global.floormaterial = 4;
// Skip blanket deactivation of solids and enemies; view-region activation still runs.
global.objdeactivate = 0;