// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 60;
global.mapoffsety = 22;
global.watertype = 0;
global.waterlevel = 0;
global.floormaterial = 4;
// Skip blanket deactivation of solids and enemies; view-region activation still runs.
global.objdeactivate = 0;

// Use item-room music when the optional music pack is available.
mus_change_itemroom();