// Set world-map placement, liquid state, the default footstep material, and ambient darkness.
global.mapoffsetx = 43;
global.mapoffsety = 6;
global.floormaterial = 4;
global.waterlevel = 0;
// Set the save-location key that set_start_location maps to a room and spawn position.
global.save_room = rm_a0h03a;
global.darkness = 2;
//mus_change(musArea8);

// Change the music when Samus exists; otherwise select the track for later playback.
if(instance_number(oCharacter) > 0) mus_change(musArea8);
else oMusicV2.currentbgm = musArea8;