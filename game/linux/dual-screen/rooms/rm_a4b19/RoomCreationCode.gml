// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 31;
global.mapoffsety = 55;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 4;
// Enable shaking and explosions while the escape sequence is active.
make_escape_sequence_fx(2);
// Schedule the escape controller to raise its temperature toward this room's target.
if (global.event[203] > 0) with (oA4EscapeControl) {
    gototemp = 30;
    alarm[0] = 1;
}

// Without Speed Booster in randomizer mode, remove the speed blocks; otherwise remove the alternate step blocks.
if (oControl.mod_randomgamebool == 1 && global.item[7] == 0)
{  
    with inst_130625 instance_destroy();
    with inst_130626 instance_destroy();
    with inst_130627 instance_destroy();
}
else 
{
    with inst_8DA02DED instance_destroy();
    with inst_674656A6 instance_destroy();
    with inst_FEF6377F instance_destroy();
}