// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 73;
global.mapoffsety = 28;
global.watertype = 0;
global.waterlevel = 0;
global.floormaterial = 4;
// Set the save-location key that set_start_location maps to a room and spawn position.
global.save_room = maproom;
//mus_change(musArea3A);

// Change the music when Samus exists; otherwise select the track for later playback.
if(instance_number(oCharacter) > 0) mus_change(musArea3A);
else oMusicV2.currentbgm = musArea3A;