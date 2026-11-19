// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 21;
global.mapoffsety = 50;
global.waterlevel = 0;
global.floormaterial = 1;
// Restore lava only while the saved drainage stage leaves this room flooded.
if (global.lavastate == 9) make_liquid(1, 880, 0, 0, 0, 0, 0);
// Allow the player's culling pass to deactivate solids and enemies before reactivating nearby instances.
global.objdeactivate = 1;