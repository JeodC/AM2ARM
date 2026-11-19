// Offset this room's local map cells into the world map.
global.mapoffsetx = 68;
global.mapoffsety = 48;
// Create the water surface and immersion effects at the configured height.
make_liquid(0, 80, 0, 0, 0, 0, 1);
// Set the save-location key that set_start_location maps to a room and spawn position.
global.save_room = rm_controller;
// Set the default material inherited by solids for footstep sounds.
global.floormaterial = 4;

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