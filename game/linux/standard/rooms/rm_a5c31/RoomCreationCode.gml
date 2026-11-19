// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 63;
global.mapoffsety = 46;
global.floormaterial = 4;
global.waterlevel = 0;
// Skip blanket deactivation of solids and enemies; view-region activation still runs.
global.objdeactivate = 0;

// Choose the room music from the saved distribution-center power state.
if (global.event[250] > 0) {
    mus_change(musArea5B);
} else mus_change(musArea5A);