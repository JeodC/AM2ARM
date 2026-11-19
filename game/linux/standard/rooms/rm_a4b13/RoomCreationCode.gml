// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 32;
global.mapoffsety = 56;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 4;
// Enable shaking and explosions while the escape sequence is active.
make_escape_sequence_fx(2);
// Schedule the escape controller to raise its temperature toward this room's target.
if (global.event[203] > 0) with (oA4EscapeControl) {
    gototemp = 20;
    alarm[0] = 1;
}
// After the early escape stage, remove the door, its blocking solid, and the matching tiles.
if (global.event[203] > 1) {
    with (inst_130151) instance_destroy();
    with (inst_130160) instance_destroy();
    tile_layer_delete(-101);
}
// Reveal each later escape tile layer only after its recorded stage has been reached.
if (global.event[203] < 3) tile_layer_hide(-102);
if (global.event[203] < 4) tile_layer_hide(-103);
if (global.event[203] < 5) tile_layer_hide(-104);
if (global.event[203] < 6) tile_layer_hide(-105);