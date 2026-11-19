// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 66;
global.mapoffsety = 42;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 4;
// Skip blanket deactivation of solids and enemies; view-region activation still runs.
global.objdeactivate = 0;
// Choose the room music from the saved distribution-center power state.
if (global.event[250] > 0) {
    mus_change(musArea5B);
} else mus_change(musArea5A);
// Keep these destroyed blocks from regenerating during this room visit.
with (oBlockScrew) regentime = -1;