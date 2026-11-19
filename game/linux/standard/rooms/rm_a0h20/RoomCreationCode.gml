// Offset this room's local map cells into the world map.
global.mapoffsetx = 50;
global.mapoffsety = 36;
// Create the lava surface and its background and immersion effects.
make_liquid(1, 176, 0, 0, 0, 0, 0);
// Set the default material inherited by solids for footstep sounds.
global.floormaterial = 1;
// Select the room ambience for player, weapon, and enemy sound effects.
SoundFX_Preset(1);