// Set world-map placement, liquid state, the default footstep material, and ambient darkness.
global.mapoffsetx = 34;
global.mapoffsety = 40;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 4;
global.darkness = 0;
// Apply the unpowered-room darkness while the facility power switch is still off.
if (global.event[200] == 0) global.darkness = 3;
mus_change(musItemAmb);