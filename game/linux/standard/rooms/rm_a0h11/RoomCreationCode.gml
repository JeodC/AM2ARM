// Set world-map placement and liquid state.
global.mapoffsetx = 46;
global.mapoffsety = 23;
global.waterlevel = 0;
// Restore the lava height for the saved drainage stage.
if (global.lavastate <= 3) {
    make_liquid(1, 224, 0, 0, 0, 0, 0);
} else if (global.lavastate <= 5) make_liquid(1, 944, 0, 0, 0, 0, 0);
// Set the default material inherited by solids for footstep sounds.
global.floormaterial = 1;
mus_change(mus_get_main_song());