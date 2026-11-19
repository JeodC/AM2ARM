// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 25;
global.mapoffsety = 54;
global.floormaterial = 1;
global.waterlevel = 0;
global.watertype = 0;
// Restore lava only while the saved drainage stage leaves this room flooded.
if (global.lavastate == 8) make_liquid(1, 440, 0, 0, 0, 0, 0);