// Set world-map placement, liquid state, the default footstep material, and ambient darkness.
global.mapoffsetx = 22;
global.mapoffsety = 39;
global.waterlevel = 0;
global.floormaterial = 5;
// Set the save-location key that set_start_location maps to a room and spawn position.
global.save_room = rm_a0h02;
global.darkness = 3;
//mus_change(musArea6A);

// Change the music when Samus exists; otherwise select the track for later playback.
if(instance_number(oCharacter) > 0) mus_change(musArea6A);
else oMusicV2.currentbgm = musArea6A;