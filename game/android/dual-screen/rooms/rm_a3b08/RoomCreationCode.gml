// Set world-map placement, liquid state, the default footstep material, and ambient darkness.
global.mapoffsetx = 57;
global.mapoffsety = 30;
global.watertype = 0;
global.waterlevel = 0;
global.floormaterial = 5;
global.darkness = 3;
// Skip blanket deactivation of solids and enemies; view-region activation still runs.
global.objdeactivate = 0;
// Select the room ambience for player, weapon, and enemy sound effects.
SoundFX_Preset(2);

// Choose which barrier to remove from the randomizer mode and the available movement equipment.
if(oControl.mod_randomgamebool == 1) {
    if ((oControl.mod_septoggs_bombjumps_easy == 0 && global.item[0] == 1)) {   
        with(inst_E819C452) instance_destroy();
        with(inst_440A3219) instance_destroy();
        with(inst_E010BE01) instance_destroy();
    }
    else if(global.item[2] == 1 || global.item[6] == 1 || global.item[4] == 1) {        
        with(inst_E819C452) instance_destroy();
        with(inst_440A3219) instance_destroy();
        with(inst_E010BE01) instance_destroy();
    }
    // Without those movement options, remove the solid barrier and its tile instead.
    else {
        with(inst_120764) instance_destroy();
        tile_layer_delete_at(-105, 848, 192);
    }
}
else {
    with(inst_E819C452) instance_destroy();
    with(inst_440A3219) instance_destroy();
    with(inst_E010BE01) instance_destroy();
}