// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 18;
global.mapoffsety = 53;
global.floormaterial = 1;
global.waterlevel = 0;
global.watertype = 0;
// Restore the lava height for the saved drainage stage.
if (global.lavastate == 8) {
    make_liquid(1, 680, 0, 0, 0, 0, 0);
} else if (global.lavastate == 9) make_liquid(1, 160, 0, 0, 0, 0, 0);
// Move or remove the scenery layers to match the passage exposed at each drainage stage.
if (global.lavastate >= 9) {
    tile_layer_shift(-101, -32, 48);
    tile_layer_shift(-102, -32, 48);
}
if (global.lavastate >= 10) tile_layer_delete(-102);
if (global.lavastate < 10) tile_layer_delete(-99);