// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 66;
global.mapoffsety = 14;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 3;
// Only the leftmost speed blocks regenerate quickly; keep the other listed blocks broken for this visit.
with (oBlockSpeed) if (x > 80) {
    regentime = -1;
} else regentime = 8;
with (oBlockBomb) regentime = -1;
with (oBlockScrew) regentime = -1;
with (oBlockSMissile) regentime = -1;

// Create the pickups selected by this game's item mapping.
instance_create(72, 656, scr_itemsopen(oControl.mod_110));