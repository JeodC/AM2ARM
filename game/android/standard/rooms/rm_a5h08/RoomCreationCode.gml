// Offset this room's local map cells into the world map.
global.mapoffsetx = 67;
global.mapoffsety = 42;
// Create the water surface and immersion effects at the configured height.
make_liquid(0, 1104, 1, 1, 0.05, 0.3, 1);
// Set the default material inherited by solids for footstep sounds.
global.floormaterial = 1;