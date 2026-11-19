// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 16;
global.mapoffsety = 52;
global.waterlevel = 0;
global.floormaterial = 1;
// Restore lava only while the saved drainage stage leaves this room flooded.
if (global.lavastate == 9) make_liquid(1, 400, 0, 0, 0, 0, 0);