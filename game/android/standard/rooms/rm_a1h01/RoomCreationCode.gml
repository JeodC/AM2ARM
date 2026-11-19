// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 51;
global.mapoffsety = 13;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 3;
// Restore the opened boss passage by moving its artwork and removing the matching collision piece.
if (global.event[51]) {
    tile_layer_shift(-99, -32, 0);
    tile_layer_shift(-98, 32, 0);
    with (inst_107511) instance_destroy();
}
mus_change(musCaveAmbience);