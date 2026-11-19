// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 28;
global.mapoffsety = 19;
global.waterlevel = 0;
global.floormaterial = 1;
mus_change(musArea2A);
// Skip blanket deactivation of solids and enemies; view-region activation still runs.
global.objdeactivate = 0;