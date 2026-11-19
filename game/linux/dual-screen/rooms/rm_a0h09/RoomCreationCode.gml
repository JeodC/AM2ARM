// Set world-map placement and liquid state.
global.mapoffsetx = 47;
global.mapoffsety = 21;
global.waterlevel = 0;
// Restore lava only while the saved drainage stage leaves this room flooded.
if (global.lavastate <= 2) make_liquid(1, 232, 0, 0, 0, 0, 0);
// Set the default material inherited by solids for footstep sounds.
global.floormaterial = 1;