// Set world-map placement and the default footstep material.
global.mapoffsetx = 20;
global.mapoffsety = 53;
global.floormaterial = 1;
// Restore lava only while the saved drainage stage leaves this room flooded.
if (global.lavastate == 9) make_liquid(1, 160, 0, 0, 0, 0, 0);