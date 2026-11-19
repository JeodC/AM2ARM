// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 35;
global.mapoffsety = 42;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 1;
// Allow the player's culling pass to deactivate solids and enemies before reactivating nearby instances.
global.objdeactivate = 1;
// Enable shaking and explosions while the escape sequence is active.
make_escape_sequence_fx(2);
// Schedule the escape controller to raise its temperature toward this room's target.
if (global.event[203] > 0) with (oA4EscapeControl) {
    gototemp = 90;
    alarm[0] = 1;
}