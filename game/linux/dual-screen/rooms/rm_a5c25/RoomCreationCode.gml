// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 60;
global.mapoffsety = 44;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 4;
// Skip blanket deactivation of solids and enemies; view-region activation still runs.
global.objdeactivate = 0;

// Create the pickups selected by this game's item mapping.
instance_create(96, 128, scr_itemsopen(oControl.mod_301));