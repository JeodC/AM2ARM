// Set world-map placement and liquid state.
global.mapoffsetx = 47;
global.mapoffsety = 13;
global.waterlevel = 0;
// Restore lava only while the saved drainage stage leaves this room flooded.
if (global.lavastate <= 1) make_liquid(1, 672, 0, 0, 0, 0, 0);
mus_change(mus_get_main_song());
// Set the default material inherited by solids for footstep sounds.
global.floormaterial = 1;