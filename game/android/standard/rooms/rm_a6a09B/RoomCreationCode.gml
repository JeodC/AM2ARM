// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 24;
global.mapoffsety = 47;
global.waterlevel = 0;
global.floormaterial = 1;
// Skip blanket deactivation of solids and enemies; view-region activation still runs.
global.objdeactivate = 0;
// Keep this encounter layer hidden until the first Omega trigger has fired.
if (global.event[300] == 0) tile_layer_hide(100);