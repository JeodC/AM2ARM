// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 34;
global.mapoffsety = 35;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 4;
// Apply the unpowered-room darkness while the facility power switch is still off.
if (global.event[200] == 0) global.darkness = 3;
// Allow the player's culling pass to deactivate solids and enemies before reactivating nearby instances.
global.objdeactivate = 1;