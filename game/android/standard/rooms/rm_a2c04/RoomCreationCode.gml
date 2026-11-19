// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 27;
global.mapoffsety = 24;
global.waterlevel = 0;
global.floormaterial = 5;
// Select the room ambience for player, weapon, and enemy sound effects.
SoundFX_Preset(3);
// Refresh Metroid sound ambience from the current room preset.
SetAmb_Monsters();