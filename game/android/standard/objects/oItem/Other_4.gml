
// Remove an already collected item when the room starts, retaining its completed map marker.
if (global.item[itemid])
{        
    myposx = floor(x / 320);
    myposy = floor((y - 8) / 240);
    mapposx = myposx + global.mapoffsetx;
    mapposy = myposy + global.mapoffsety;
    // The relocated reactor pickup keeps its original map cell, not the E-tank's.
    if ((room == rm_a4b02b) && (itemid == oControl.mod_253)) {
        global.dmap[37, 58] = 2;
    } else if (distance_to_object(oItem) > 180) {
        global.dmap[mapposx, mapposy] = 2;
    }
    instance_destroy(); //original
}


