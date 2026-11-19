// Offset this room's local map cells into the world map.
global.mapoffsetx = 6;
global.mapoffsety = 24;
// Create the water surface and immersion effects at the configured height.
make_liquid(0, 1904, 1, 0, 0, 0, 0);
// Set the default material inherited by solids for footstep sounds.
global.floormaterial = 1;
mus_change(musArea6A);