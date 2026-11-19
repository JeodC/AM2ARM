// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 16;
global.mapoffsety = 49;
global.waterlevel = 0;
global.floormaterial = 1;
// Skip blanket deactivation of solids and enemies; view-region activation still runs.
global.objdeactivate = 0;
// Lower the scenery to match the collision height restored after the saved scan event.
if (global.event[305] > 0) tile_layer_shift(-99, 0, 144);