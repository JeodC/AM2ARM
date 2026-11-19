// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 33;
global.mapoffsety = 42;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 4;
// Enable shaking while the escape sequence is active.
make_escape_sequence_fx(1);
// Skip blanket deactivation of solids and enemies; view-region activation still runs.
global.objdeactivate = 0;
// Match the blast-door tiles and collision pieces to the final escape stage.
if (global.event[203] < 9) {
    tile_layer_hide(-101);
    with (inst_128787) y -= 240;
    with (inst_128788) y -= 240;
    with (inst_128790) y -= 240;
    with (inst_128789) y -= 240;
} else with (oA4BlastDoor) instance_destroy();
// Schedule the escape controller to raise its temperature toward this room's target.
if (global.event[203] > 0 && global.event[203] < 9) with (oA4EscapeControl) {
    gototemp = 100;
    alarm[0] = 1;
}
// Use the normal area music before the escape or after it reaches its final stage.
if (global.event[203] == 0 || global.event[203] == 9) mus_change(musArea4B);