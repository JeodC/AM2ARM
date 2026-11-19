// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 65;
global.mapoffsety = 23;
global.watertype = 0;
global.waterlevel = 0;
global.floormaterial = 4;
// Refresh Metroid sound ambience from the current room preset.
SetAmb_Monsters();

// Create the pickups selected by this game's item mapping.
instance_create(240, 96, scr_itemsopen(oControl.mod_204));