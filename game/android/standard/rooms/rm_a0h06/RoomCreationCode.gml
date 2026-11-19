// Set world-map placement and liquid state.
global.mapoffsetx = 38;
global.mapoffsety = 13;
global.waterlevel = 0;
// Restore lava only while the saved drainage stage leaves this room flooded.
if (global.lavastate == 0) make_liquid(1, 208, 0, 0, 0, 0, 0);