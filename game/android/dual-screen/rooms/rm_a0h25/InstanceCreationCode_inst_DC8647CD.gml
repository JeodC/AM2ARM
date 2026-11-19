// Keep this helper Septogg accessible only when the room's conditions allow it.
if (oControl.mod_randomgamebool == 1)
{
    if (scr_septoggs_246()) { xstart = -500; }
}
else if (global.item[0] == 1 || scr_septoggs_246()) { xstart = -500; } // 1.5.1 fix

// Set how far this Septogg can lift Samus above its starting height.
lift = 50;