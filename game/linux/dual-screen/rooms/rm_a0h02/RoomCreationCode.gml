// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 30;
global.mapoffsety = 7;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 2;
// Select the room ambience for player, weapon, and enemy sound effects.
SoundFX_Preset(1);
// Choose the outdoor backgrounds and ship appearance for the saved time of day.
load_timeofday_bgs(global.timeofday);