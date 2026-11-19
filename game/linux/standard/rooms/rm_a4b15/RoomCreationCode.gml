// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 33;
global.mapoffsety = 58;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 4;
// Enable shaking and explosions while the escape sequence is active.
make_escape_sequence_fx(2);
// Keep the door, blocking solid, and matching tiles removed after the early escape stage.
if (global.event[203] > 1) {
    with (inst_130192) instance_destroy();
    with (inst_130195) instance_destroy();
    tile_layer_delete(-101);
}