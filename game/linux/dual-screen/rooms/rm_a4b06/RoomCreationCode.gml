// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 36;
global.mapoffsety = 44;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 1;
// Enable shaking and explosions while the escape sequence is active.
make_escape_sequence_fx(2);
// Hide the escape scenery until the sequence has started.
if (global.event[203] == 0) tile_layer_delete(-101);
// Schedule the escape controller to raise its temperature toward this room's target.
if (global.event[203] > 0) with (oA4EscapeControl) {
    gototemp = 60;
    alarm[0] = 1;
}