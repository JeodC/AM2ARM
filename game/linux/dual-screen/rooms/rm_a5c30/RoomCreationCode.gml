// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 70;
global.mapoffsety = 48;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 4;
// Create the water surface and immersion effects at the configured height.
make_liquid(0, 80, 0, 0, 0, 0, 1);