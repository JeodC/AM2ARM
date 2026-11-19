// Set world-map placement and liquid state.
global.mapoffsetx = 43;
global.mapoffsety = 15;
global.waterlevel = 0;
// Restore lava only while the saved drainage stage leaves this room flooded.
if (global.lavastate <= 1) make_liquid(1, 192, 0, 0, 0, 0, 0);
mus_change(mus_get_main_song());
// Set the default material inherited by solids for footstep sounds.
global.floormaterial = 1;
// Advance an existing earthquake sequence to at least this point when entering the room.
if (instance_exists(oBigQuake)) with (oBigQuake) if (statetime < 590) statetime = 590;

// Remove these bomb blocks for the listed randomizer and game modes.
if (oControl.mod_purerandombool == 1 || oControl.mod_splitrandom == 1 || global.gamemode == 2)
//if (oControl.mod_purerandombool == 1 || oControl.mod_splitrandom = 1 || (oControl.mod_randomgamebool == 1 && oControl.mod_bombblocks == 1))
{
    with (inst_102589) { instance_destroy(); }
    with (inst_102590) { instance_destroy(); }
    with (inst_102591) { instance_destroy(); }
    with (inst_102592) { instance_destroy(); }
}