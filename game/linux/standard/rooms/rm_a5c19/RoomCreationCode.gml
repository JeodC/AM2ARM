// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 70;
global.mapoffsety = 43;
global.floormaterial = 4;
global.waterlevel = 0;
global.watertype = 0;
// Set the save-location key that set_start_location maps to a room and spawn position.
global.save_room = rm_death;

/*
if (global.event[250] > 0) {
    mus_change(musArea5B);
} else mus_change(musArea5A);
*/

// Choose the room music from the saved distribution-center power state.
if (global.event[250] > 0) 
{
    // Change the music when Samus exists; otherwise select the track for later playback.
    if(instance_number(oCharacter) > 0) mus_change(musArea5B);
    else oMusicV2.currentbgm = musArea5B;
}
else
{
    if(instance_number(oCharacter) > 0) mus_change(musArea5A);
    else oMusicV2.currentbgm = musArea5A;
}