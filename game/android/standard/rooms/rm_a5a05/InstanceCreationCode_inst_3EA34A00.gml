// Keep this helper Septogg accessible only when the room's conditions allow it.
if (oControl.mod_randomgamebool == 1 && oControl.mod_previous_room == rm_a5a06)
{
    if (scr_septoggs_2467()) {  xstart = -500; }
}
else { xstart = -500; }

// Set how far this Septogg can lift Samus above its starting height.
if (global.item[9] == 1) lift = 400;
else lift = 75;