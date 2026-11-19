// Set world-map placement and liquid state.
global.mapoffsetx = 21;
global.mapoffsety = 15;
global.waterlevel = 0;
global.watertype = 0;
// Refresh Metroid sound ambience from the current room preset.
SetAmb_Monsters();

// Populate this Septogg after the first Metroid has been marked defeated.
if(global.metdead[0] == 1) instance_create(68, 48, oElderSeptogg);