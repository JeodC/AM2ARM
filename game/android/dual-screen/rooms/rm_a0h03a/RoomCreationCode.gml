// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 37;
global.mapoffsety = 13;
global.waterlevel = 0;
global.watertype = 0;
// Set the save-location key that set_start_location maps to a room and spawn position.
global.save_room = titleroom;
global.floormaterial = 1;
// Select the room ambience for player, weapon, and enemy sound effects.
SoundFX_Preset(1);
//mus_change(mus_get_main_song());

// Change the music when Samus exists; otherwise select the track for later playback.
if(instance_number(oCharacter) > 0) mus_change(mus_get_main_song());
else oMusicV2.currentbgm = mus_get_main_song();