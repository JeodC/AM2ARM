// Offset this room's local map cells into the world map.
global.mapoffsetx = 41;
global.mapoffsety = 24;
// Create the lava surface and its background and immersion effects.
make_liquid(1, 672, 0, 0, 0, 0, 0);
// Set the darkness level consumed by room lighting setup.
global.darkness = 0;
// Keep the entrance tile layer removed after its Power Bomb chain has opened.
if (global.event[176] == 1) tile_layer_delete(-111);
mus_change(musCaveAmbience);
// Switch later outdoor background selection to twilight.
global.timeofday = 1;