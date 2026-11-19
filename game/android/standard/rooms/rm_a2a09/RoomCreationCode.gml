// Set world-map placement and the default footstep material.
global.mapoffsetx = 33;
global.mapoffsety = 23;
global.floormaterial = 4;
// Create the water surface and immersion effects at the configured height.
make_liquid(0, 192, 0, 1, 0.01, 0.1, 0);
mus_change(musArea2A);
// Mark the turbine-drainage sequence complete on entering this downstream room.
global.event[101] = 4;

// Create the pickups selected by this game's item mapping.
instance_create(56, 48, scr_itemsopen(oControl.mod_151));