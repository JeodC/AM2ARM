// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 34;
global.mapoffsety = 33;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 4;

// Choose the room music from the saved facility power-switch state.
if (global.event[200] == 0) {
    mus_change(musCaveAmbienceA4);
} else mus_change(musArea4A);

// Apply the unpowered-room darkness while the facility power switch is still off.
if (global.event[200] == 0) global.darkness = 3;