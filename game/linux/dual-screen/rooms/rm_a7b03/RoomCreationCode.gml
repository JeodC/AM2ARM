// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 7;
global.mapoffsety = 22;
global.waterlevel = 0;
global.floormaterial = 3;
// Choose the room music from the saved egg-encounter state.
if (global.event[302] == 0) {
    mus_change(musArea7A);
} else mus_change(musArea7C);