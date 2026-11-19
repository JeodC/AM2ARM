// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 4;
global.mapoffsety = 20;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 1;
mus_change(musHatchling);
// Allow the player's culling pass to deactivate solids and enemies before reactivating nearby instances.
global.objdeactivate = 1;