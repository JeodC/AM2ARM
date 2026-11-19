// Set world-map placement, liquid state, the default footstep material, and ambient darkness.
global.mapoffsetx = 26;
global.mapoffsety = 31;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 5;
global.darkness = 2;
// Skip blanket deactivation of solids and enemies; view-region activation still runs.
global.objdeactivate = 0;
// Create the lava surface and its background and immersion effects.
make_liquid(1, 230, 0, 0, 0, 0, 0);