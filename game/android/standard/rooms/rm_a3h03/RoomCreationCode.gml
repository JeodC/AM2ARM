// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 54;
global.mapoffsety = 22;
global.watertype = 0;
global.waterlevel = 0;
global.floormaterial = 3;
mus_change(musCaveAmbience);
// Keep these destroyed blocks from regenerating during this room visit.
with (oBlockSpeed) regentime = -1;