// Set world-map placement and liquid state.
global.mapoffsetx = 50;
global.mapoffsety = 24;
global.watertype = 1;
// Restore lava only while the saved drainage stage leaves this room flooded.
if (global.lavastate <= 4) make_liquid(1, 240, 0, 0, 0, 0, 0);
// Set the default material inherited by solids for footstep sounds.
global.floormaterial = 1;
mus_change(mus_get_main_song());