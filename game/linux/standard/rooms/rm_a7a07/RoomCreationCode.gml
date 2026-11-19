// Offset this room's local map cells into the world map.
global.mapoffsetx = 7;
global.mapoffsety = 34;
// Create the water surface and immersion effects at the configured height.
make_liquid(0, 184, 1, 0, 0, 0, 0);
// Set the default material inherited by solids for footstep sounds.
global.floormaterial = 1;