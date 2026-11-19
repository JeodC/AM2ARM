// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 54;
global.mapoffsety = 34;
global.watertype = 0;
global.waterlevel = 0;
global.floormaterial = 1;
// Set the save-location key that set_start_location maps to a room and spawn position.
global.save_room = testroom;
//mus_change(musCaveAmbience);

// Change the music when Samus exists; otherwise select the track for later playback.
if(instance_number(oCharacter) > 0) mus_change(musCaveAmbience);
else oMusicV2.currentbgm = musCaveAmbience;