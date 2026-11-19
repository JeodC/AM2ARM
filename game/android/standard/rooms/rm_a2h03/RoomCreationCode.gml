// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 30;
global.mapoffsety = 17;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 1;
// Select the room ambience for player, weapon, and enemy sound effects.
SoundFX_Preset(1);
// Refresh Metroid sound ambience from the current room preset.
SetAmb_Monsters();