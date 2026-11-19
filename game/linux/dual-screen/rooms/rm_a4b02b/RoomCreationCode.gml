// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 33;
global.mapoffsety = 46;
global.waterlevel = 0;
global.watertype = 0;
global.floormaterial = 4;

// Repair an old false collected marker without revealing an unexplored cell.
if ((global.dmap[33, 46] == 2) && !global.item[oControl.mod_254]) {
    global.dmap[33, 46] = 1;
}

// Create the pickups selected by this game's item mapping.
instance_create(112, 112, scr_itemsopen(oControl.mod_254));
instance_create(528, 64, scr_itemsopen(oControl.mod_255));
instance_create(314, 192, scr_itemsopen(oControl.mod_253)); // fix for random/newgames where power bombs in explosion can be skipped
