// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 16;
global.mapoffsety = 55;
global.floormaterial = 1;
global.waterlevel = 0;
global.watertype = 0;
// Restore the lava and select the scenery layer for the saved drainage stage.
if (global.lavastate <= 8) {
    make_liquid(1, 200, 0, 0, 0, 0, 0);
    tile_layer_delete(-98);
}
if (global.lavastate > 8) tile_layer_delete(-99);