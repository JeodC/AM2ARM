// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 34;
global.mapoffsety = 39;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 4;
// Set the save-location key that set_start_location maps to a room and spawn position.
global.save_room = gameintroroom;
// Apply the unpowered-room darkness while the facility power switch is still off.
if (global.event[200] == 0) global.darkness = 3;
//if (global.event[200] == 0) {
//    mus_change(musCaveAmbienceA4);
//} else mus_change(musArea4A);
// Schedule the environment scan if its log state permits it.
scan_log(26, get_text("ScanEvents", "ScanEnvironment"), 120, 0);

// Choose the room music from the saved facility power-switch state.
if (global.event[200] == 0) 
{
    // Change the music when Samus exists; otherwise select the track for later playback.
    if(instance_number(oCharacter) > 0) mus_change(musCaveAmbienceA4);
    else oMusicV2.currentbgm = musCaveAmbienceA4;
}
else
{
    if(instance_number(oCharacter) > 0) mus_change(musArea4A);
    else oMusicV2.currentbgm = musArea4A;
}