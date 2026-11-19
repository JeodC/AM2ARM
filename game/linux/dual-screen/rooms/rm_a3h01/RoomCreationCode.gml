// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 52;
global.mapoffsety = 24;
global.watertype = 0;
global.waterlevel = 0;
// Set the save-location key that set_start_location maps to a room and spawn position.
global.save_room = subscreenroom;
//mus_change(musCaveAmbience);
global.floormaterial = 1;
// Select the room ambience for player, weapon, and enemy sound effects.
SoundFX_Preset(1);
// Refresh Metroid sound ambience from the current room preset.
SetAmb_Monsters();

// Change the music when Samus exists; otherwise select the track for later playback.
if(instance_number(oCharacter) > 0) mus_change(musCaveAmbience);
else oMusicV2.currentbgm = musCaveAmbience;