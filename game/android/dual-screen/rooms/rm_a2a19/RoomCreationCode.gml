// Set world-map placement and the default footstep material.
global.mapoffsetx = 30;
global.mapoffsety = 23;
global.floormaterial = 1;
// Create the water surface and immersion effects at the configured height.
make_liquid(0, 192, 0, 1, 0.01, 0.1, 0);
mus_change(musItemAmb);
// Mark the turbine-drainage sequence complete on entering this downstream room.
global.event[101] = 4;