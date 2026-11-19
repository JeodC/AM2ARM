// Offset this room's local map cells into the world map.
global.mapoffsetx = 12;
global.mapoffsety = 56;
//make_liquid(1, 232, 0, 0, 0, 0, 0);
// Create the lava surface and its background and immersion effects.
make_liquid(1, 288, 0, 0, 0, 0, 0);
// Set the default material inherited by solids for footstep sounds.
global.floormaterial = 1;
// Skip blanket deactivation of solids and enemies; view-region activation still runs.
global.objdeactivate = 0;