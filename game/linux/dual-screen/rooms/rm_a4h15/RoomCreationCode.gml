// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 38;
global.mapoffsety = 42;
global.watertype = 0;
global.waterlevel = 0;
global.floormaterial = 1;
// Choose the room music from the saved facility power-switch state.
if (global.event[200] == 0) {
    mus_change(musCaveAmbienceA4);
} else mus_change(musArea4A);

// Create the pickups selected by this game's item mapping.
instance_create(240, 352, scr_itemsopen(oControl.mod_259));