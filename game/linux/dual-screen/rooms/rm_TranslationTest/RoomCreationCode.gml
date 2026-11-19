// Set world-map placement and the default footstep material.
global.mapoffsetx = 31;
global.mapoffsety = 12;
global.floormaterial = 5;
// Show the collision-solid sprites to make the room's collision layout visible.
with (oSolid) visible = true;
// Skip blanket deactivation of solids and enemies; view-region activation still runs.
global.objdeactivate = 0;