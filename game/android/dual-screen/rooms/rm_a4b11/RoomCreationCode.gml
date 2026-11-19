// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 34;
global.mapoffsety = 47;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 4;
// Enable shaking and explosions while the escape sequence is active.
make_escape_sequence_fx(2);
// Hide the escape scenery until the sequence has started.
if (global.event[203] == 0) tile_layer_delete(-101);