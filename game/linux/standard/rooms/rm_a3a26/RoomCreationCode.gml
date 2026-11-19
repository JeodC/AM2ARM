// Offset this room's local map cells into the world map.
global.mapoffsetx = 72;
global.mapoffsety = 31;
// Create the lava surface and its background and immersion effects.
make_liquid(1, 192, 0, 0, 0, 0, 1);
// Set the default material inherited by solids for footstep sounds.
global.floormaterial = 1;
// Select the room ambience for player, weapon, and enemy sound effects.
SoundFX_Preset(1);
// Refresh Metroid sound ambience from the current room preset.
SetAmb_Monsters();