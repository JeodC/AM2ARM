// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 34;
global.mapoffsety = 53;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 1;

// Choose the scenery variant from whether the power-plant escape has started.
if (global.event[203] > 0) {
    tile_layer_delete(-110);
} else {
    tile_layer_delete(-111);
}