// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 65;
global.mapoffsety = 22;
global.watertype = 0;
global.waterlevel = 0;
global.floormaterial = 4;
// Select the room ambience for player, weapon, and enemy sound effects.
SoundFX_Preset(1);

// Create the pickups selected by this game's item mapping.
instance_create(32, 80, scr_itemsopen(oControl.mod_200));