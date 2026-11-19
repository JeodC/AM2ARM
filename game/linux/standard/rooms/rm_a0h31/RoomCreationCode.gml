// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 43;
global.mapoffsety = 44;
global.watertype = 1;
global.floormaterial = 1;
// Restore the lava and remaining scenery for the saved drainage stage.
if (global.lavastate <= 7) {
    make_liquid(1, 192, 0, 0, 0, 0, 0);
} else tile_layer_delete(-90);
mus_change(mus_get_main_song());
// Allow the player's culling pass to deactivate solids and enemies before reactivating nearby instances.
global.objdeactivate = 1;