// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 31;
global.mapoffsety = 56;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 4;
// Restore the raised scenery before this escape stage, then remove the opened route's blocking solid and tiles.
if (global.event[203] < 8) {
    tile_layer_shift(-102, 0, -64);
} else {
    tile_layer_delete(-101);
    with (inst_130180) instance_destroy();
}
// Enable shaking and explosions while the escape sequence is active.
make_escape_sequence_fx(2);