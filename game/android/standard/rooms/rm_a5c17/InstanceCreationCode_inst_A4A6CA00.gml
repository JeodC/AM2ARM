// Keep this helper Septogg accessible only when the room's conditions allow it.
if (oControl.mod_randomgamebool == 1)
{
    if (oControl.mod_septoggs_bombjumps_easy == 0 && global.item[0] == 1) { xstart = -500; }
    else if (scr_septoggs_26()) { xstart = -500; } // was scr_septoggs_246()
}
else { xstart = -500; }

parent = 0;

// Set how far this Septogg can lift Samus above its starting height.
if (global.item[4] == 0) lift = 75; // this isn't technically needed, but it's harder with high jump only. It's like area 1 wall jump.