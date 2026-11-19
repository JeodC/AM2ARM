// Keep this helper Septogg accessible only when the room's conditions allow it.
if (oControl.mod_randomgamebool == 1)
{  
    if (oControl.mod_septoggs_bombjumps_easy == 0 && global.item[0] == 1) { xstart = -500; }
    else if (scr_septoggs_2467()) { xstart = -500; }    
}
else { xstart = -500; }
