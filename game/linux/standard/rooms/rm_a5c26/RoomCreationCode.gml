// Set world-map placement and the default footstep material.
global.mapoffsetx = 62;
global.mapoffsety = 48;
global.floormaterial = 4;
// Skip blanket deactivation of solids and enemies; view-region activation still runs.
global.objdeactivate = 0;
// Create the water surface and immersion effects at the configured height.
make_liquid(0, 80, 0, 0, 0, 0, 1);