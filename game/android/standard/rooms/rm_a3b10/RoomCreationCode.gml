// Set world-map placement, liquid state, the default footstep material, and ambient darkness.
global.mapoffsetx = 61;
global.mapoffsety = 27;
global.watertype = 0;
global.waterlevel = 0;
global.floormaterial = 5;
global.darkness = 4;
// Select the room ambience for player, weapon, and enemy sound effects.
SoundFX_Preset(2);

// Create the pickups selected by this game's item mapping.
instance_create(608, 368, scr_itemsopen(oControl.mod_209));