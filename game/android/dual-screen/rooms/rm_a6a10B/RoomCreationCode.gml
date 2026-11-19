// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 23;
global.mapoffsety = 53;
global.watertype = 0;
global.waterlevel = 0;
global.floormaterial = 1;
// Set the save-location key that set_start_location maps to a room and spawn position.
global.save_room = rm_a0h03b;
//mus_change(mus_get_main_song());
// Allow the player's culling pass to deactivate solids and enemies before reactivating nearby instances.
global.objdeactivate = 1;

// Restore lava only while the saved drainage stage leaves this room flooded.
if (global.lavastate == 9) make_liquid(1, 160, 0, 0, 0, 0, 0); // I think this is right lol

// Change the music when Samus exists; otherwise select the track for later playback.
if(instance_number(oCharacter) > 0) mus_change(mus_get_main_song());
else oMusicV2.currentbgm = mus_get_main_song();