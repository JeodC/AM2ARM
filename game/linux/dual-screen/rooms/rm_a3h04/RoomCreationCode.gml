// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 58;
global.mapoffsety = 18;
global.watertype = 0;
global.waterlevel = 0;
global.floormaterial = 3;
// Allow the player's culling pass to deactivate solids and enemies before reactivating nearby instances.
global.objdeactivate = 1;
// When leaving optional item music, resume the previous area theme or the cave ambience.
if (global.optionalMusicInstalled) {
    if(oMusicV2.currentbgm == musItemAmb2) {
        if (oMusicV2.previousbgm == musArea3A) mus_change(musArea3A);
        else mus_change(musCaveAmbience);
    }
}
// Create the pickups selected by this game's item mapping.
instance_create(2592, 1120, scr_itemsopen(oControl.mod_202));
instance_create(64, 1648, scr_itemsopen(oControl.mod_211));