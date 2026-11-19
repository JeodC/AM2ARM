// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 33;
global.mapoffsety = 56;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 4;
// Enable shaking and explosions while the escape sequence is active.
make_escape_sequence_fx(2);
//if (global.event[203] == 0) mus_change(musArea4B);
if (global.event[203] == 0)
{
    // Change the music when Samus exists; otherwise select the track for later playback.
    if(instance_number(oCharacter) > 0) mus_change(musArea4B);
    else oMusicV2.currentbgm = musArea4B;
}


// Restore the door artwork before this escape stage, or remove its door instance afterward.
if (global.event[203] < 7) {
    tile_layer_hide(-101);
} else with (inst_130129) instance_destroy();
// Set the save-location key that set_start_location maps to a room and spawn position.
global.save_room = rm_subscreen;

// GM2026 fix: room_get_name(room) returns the string "rm_a4b12", and GM2026 refuses to coerce a
// string to bool in a condition (GMS1.4 silently treated a non-empty string as true) — FATAL
// "unable to convert string to bool" on entry once event[203] > 0 (the post-bomb escape). The
// name check is a no-op (always non-empty) and the body below is dead code; compare to "" so the
// operand is a real bool while preserving the original always-true behavior.
if (global.event[203] > 0 && room_get_name(room) != "")
{
//instance_create(144, 160, oSaveStationBroken); // 144, 160
//with (inst_130135) sprite_index = sSaveBroken;
//with (inst_130136) instance_destroy();

}