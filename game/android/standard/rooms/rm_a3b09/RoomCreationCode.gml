// Set world-map placement, liquid state, the default footstep material, and ambient darkness.
global.mapoffsetx = 60;
global.mapoffsety = 28;
global.watertype = 0;
global.waterlevel = 0;
global.floormaterial = 5;
global.darkness = 3;
// Allow the player's culling pass to deactivate solids and enemies before reactivating nearby instances.
global.objdeactivate = 1;
// Select the room ambience for player, weapon, and enemy sound effects.
SoundFX_Preset(1);