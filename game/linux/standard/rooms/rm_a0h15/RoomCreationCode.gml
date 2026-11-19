// Set world-map placement, liquid state, and ambient darkness.
global.mapoffsetx = 45;
global.mapoffsety = 24;
global.watertype = 1;
global.darkness = 3;
// Arm the Metroid trigger that checks whether this approach room has been entered.
global.event[170] = 1;

// Create the pickups selected by this game's item mapping.
instance_create(224, 208, scr_itemsopen(oControl.mod_215));