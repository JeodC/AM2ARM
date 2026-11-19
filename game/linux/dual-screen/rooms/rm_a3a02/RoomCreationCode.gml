// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 64;
global.mapoffsety = 21;
global.waterlevel = 0;
// Set the save-location key that set_start_location maps to a room and spawn position.
global.save_room = itemroom;
global.floormaterial = 4;

// Create the pickups selected by this game's item mapping.
instance_create(512, 208, scr_itemsopen(oControl.mod_203));

// Change the music when Samus exists; otherwise select the track for later playback.
if(instance_number(oCharacter) > 0) mus_change(musArea3A);
else oMusicV2.currentbgm = musArea3A;