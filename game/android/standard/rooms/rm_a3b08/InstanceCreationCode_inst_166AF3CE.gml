// Set the lift height and keep this Septogg from spawning young.
lift = 144;
parent = 0;

// Keep this helper Septogg accessible only when the room's conditions allow it.
if (oControl.mod_randomgamebool == 1)
{
    if (oControl.mod_septoggs_bombjumps_easy == 0 && global.item[0] == 1) { xstart = -500; }
    else if (scr_septoggs_26() || instance_exists(oMGammaA3BTrigger) || instance_exists(oMGammaTriggerProx)) { xstart = -500; }
}
else { xstart = -500; }