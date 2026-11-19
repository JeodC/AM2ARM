// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 63;
global.mapoffsety = 47;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 4;

// Keep destroyed bomb blocks from regenerating during this randomizer room visit.
if (oControl.mod_randomgamebool) {
    with (oBlockBomb) {
        regentime = -1;
    }
}