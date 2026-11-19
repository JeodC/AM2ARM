// Offset this room's local map cells into the world map.
global.mapoffsetx = 47;
global.mapoffsety = 44;
// Create the water surface and immersion effects at the configured height.
make_liquid(0, 432, 0, 0, 0, 0, 0);
// Set the default material inherited by solids for footstep sounds.
global.floormaterial = 1;
// Skip blanket deactivation of solids and enemies; view-region activation still runs.
global.objdeactivate = 0;