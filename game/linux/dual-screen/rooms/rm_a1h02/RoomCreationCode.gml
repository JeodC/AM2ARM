// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 53;
global.mapoffsety = 14;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 3;
//mus_change(musCaveAmbience);
// Set the save-location key that set_start_location maps to a room and spawn position.
global.save_room = demoendroom;
// Select the room ambience for player, weapon, and enemy sound effects.
SoundFX_Preset(1);

// Change the music when Samus exists; otherwise select the track for later playback.
if(instance_number(oCharacter) > 0) mus_change(musCaveAmbience);
else oMusicV2.currentbgm = musCaveAmbience;