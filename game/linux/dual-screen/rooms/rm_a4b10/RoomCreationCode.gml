// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 35;
global.mapoffsety = 47;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 4;
// Enable shaking and explosions while the escape sequence is active.
make_escape_sequence_fx(2);
// Schedule the escape controller to raise its temperature toward this room's target.
if (global.event[203] > 0) with (oA4EscapeControl) {
    gototemp = 50;
    alarm[0] = 1;
}

// Remove the bomb-block barrier when bombs are absent and Power Bomb access is restricted by the escape state.
if (global.item[0] == 0 && ((global.ptanks == 0) || (global.ptanks == 1 && global.event[203] > 0 && global.event[203] < 9)))
{
with inst_130019 instance_destroy();
with inst_130021 instance_destroy();
}