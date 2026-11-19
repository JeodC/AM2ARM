// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 44;
global.mapoffsety = 44;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 1;
mus_change(musCaveAmbience);
// Allow the player's culling pass to deactivate solids and enemies before reactivating nearby instances.
global.objdeactivate = 1;