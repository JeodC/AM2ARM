// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 69;
global.mapoffsety = 40;
global.waterlevel = 0;
global.floormaterial = 3;


// Create a mapped replacement here only when this location no longer holds the normal Gravity Suit item.
if (oControl.mod_gravity != 9) instance_create(152, 160, scr_itemsopen(oControl.mod_gravity));