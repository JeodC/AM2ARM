// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 20;
global.mapoffsety = 55;
global.floormaterial = 1;
global.waterlevel = 0;
global.watertype = 0;
//if (global.lavastate == 8) make_liquid(1, 200, 0, 0, 0, 0, 0);
// Create the lava surface and its background and immersion effects.
make_liquid(1, 200, 0, 0, 0, 0, 0);
// Skip blanket deactivation of solids and enemies; view-region activation still runs.
global.objdeactivate = 0;