// Set world-map placement and the default footstep material.
global.mapoffsetx = 74;
global.mapoffsety = 45;
global.floormaterial = 4;

// Choose the room music from the saved distribution-center power state.
if (global.event[250] > 0) {
    mus_change(musArea5B);
} else mus_change(musArea5A);