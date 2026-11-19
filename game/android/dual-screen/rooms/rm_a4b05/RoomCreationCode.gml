// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 32;
global.mapoffsety = 45;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 4;
// Enable shaking and explosions while the escape sequence is active.
make_escape_sequence_fx(2);
// Keep only the scenery layer that matches whether the escape has started.
if (global.event[203] > 0) {
    tile_layer_delete(-102);
} else tile_layer_delete(-101);
// Schedule the escape controller to raise its temperature toward this room's target.
if (global.event[203] > 0) with (oA4EscapeControl) {
    gototemp = 70;
    alarm[0] = 1;
}