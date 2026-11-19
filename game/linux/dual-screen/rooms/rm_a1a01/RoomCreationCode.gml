// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 60;
global.mapoffsety = 11;
global.waterlevel = 0;
global.watertype = 0;
//mus_change(musArea1A);
// Set the save-location key that set_start_location maps to a room and spawn position.
global.save_room = rm_credits;
global.floormaterial = 3;

// Change the music when Samus exists; otherwise select the track for later playback.
if(instance_number(oCharacter) > 0) mus_change(musArea1A);
else oMusicV2.currentbgm = musArea1A;