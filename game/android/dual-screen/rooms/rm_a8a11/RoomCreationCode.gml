// Set world-map placement, liquid state, the default footstep material, and ambient darkness.
global.mapoffsetx = 47;
global.mapoffsety = 5;
global.floormaterial = 4;
global.waterlevel = 0;
global.darkness = 3;

// Create the pickups selected by this game's item mapping.
instance_create(888, 176, scr_itemsopen(oControl.mod_50));