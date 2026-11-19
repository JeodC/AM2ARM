// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 66;
global.mapoffsety = 30;
global.watertype = 0;
global.waterlevel = 0;
global.floormaterial = 1;
// Select the room ambience for player, weapon, and enemy sound effects.
SoundFX_Preset(1);
// Create the lava surface and its background and immersion effects.
make_liquid(1, 464, 0, 0, 0, 0, 1);