// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 26;
global.mapoffsety = 15;
global.waterlevel = 0;
global.watertype = 0;
// Set the save-location key that set_start_location maps to a room and spawn position.
global.save_room = gameoverroom;
global.floormaterial = 1;
//mus_change(mus_get_main_song());
// Record the earthquake log when its sequence controller is present.
if (instance_exists(oBigQuake) > false) add_log(3);

// Change the music when Samus exists; otherwise select the track for later playback.
if(instance_number(oCharacter) > 0) mus_change(mus_get_main_song());
else oMusicV2.currentbgm = mus_get_main_song();