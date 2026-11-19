// Set world-map placement, liquid state, the default footstep material, and ambient darkness.
global.mapoffsetx = 51;
global.mapoffsety = 22;
global.watertype = 0;
global.waterlevel = 0;
global.floormaterial = 3;
global.darkness = 0;
// Skip blanket deactivation of solids and enemies; view-region activation still runs.
global.objdeactivate = 0;
// Keep these destroyed blocks from regenerating during this room visit.
with (oBlockShoot) regentime = -1;
with (oBlockPBomb) regentime = -1;

// Create the pickups selected by this game's item mapping.
instance_create(512, 400, scr_itemsopen(oControl.mod_214));