// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 9;
global.mapoffsety = 23;
global.waterlevel = 0;
global.floormaterial = 3;
// Set the save-location key that set_start_location maps to a room and spawn position.
global.save_room = rm_a0h03;

/*
if (global.event[302] == 0) {
    mus_change(musArea7A);
} else mus_change(musArea7C);
*/

// Choose the room music from the saved egg-encounter state.
if (global.event[302] == 0)
{
    // Change the music when Samus exists; otherwise select the track for later playback.
    if(instance_number(oCharacter) > 0) mus_change(musArea7A);
    else oMusicV2.currentbgm = musArea7A;
}
else
{
    if(instance_number(oCharacter) > 0) mus_change(musArea7C);
    else oMusicV2.currentbgm = musArea7C;
}