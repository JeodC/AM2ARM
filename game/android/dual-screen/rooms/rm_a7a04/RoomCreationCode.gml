// Offset this room's local map cells into the world map.
global.mapoffsetx = 11;
global.mapoffsety = 35;
// Create the water surface and immersion effects at the configured height.
make_liquid(0, 424, 1, 0, 0, 0, 0);
// Set the default material inherited by solids for footstep sounds.
global.floormaterial = 1;