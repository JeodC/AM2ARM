// Place the platform at Samus's end of the shaft and choose the opposite stop.
if (oCharacter.y < room_height / 2) {
    y = target_top;
    targety = target_bottom;
    elev_dir = 0;
} else {
    y = target_bottom;
    targety = target_top;
    elev_dir = 1;
}
mysolid.y = y;

