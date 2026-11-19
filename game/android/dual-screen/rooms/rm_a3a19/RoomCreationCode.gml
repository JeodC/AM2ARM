// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 69;
global.mapoffsety = 27;
global.watertype = 0;
global.waterlevel = 0;
global.floormaterial = 4;
// Select the room ambience for player, weapon, and enemy sound effects.
SoundFX_Preset(1);

// Create the pickups selected by this game's item mapping.
instance_create(888, 320, scr_itemsopen(oControl.mod_207));
instance_create(1200, 192, scr_itemsopen(oControl.mod_208));

// Remove this bomb block when the listed randomizer modes lack the required Power Bomb capacity.
if ((oControl.mod_purerandombool == 1) || (oControl.mod_splitrandom == 1)) {
    if (global.maxpbombs < 2) {
        with (inst_118108) {
            instance_destroy();
        }
    }
}