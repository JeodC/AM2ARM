// Set world-map placement, liquid state, the default footstep material, and ambient darkness.
global.mapoffsetx = 50;
global.mapoffsety = 23;
global.watertype = 0;
global.waterlevel = 0;
global.floormaterial = 3;
global.darkness = 0;

// Create the pickups selected by this game's item mapping.
instance_create(112, 96, scr_itemsopen(oControl.mod_213));