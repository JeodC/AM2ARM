// GM2026: this sprite-less instance is created at (0,0) — the room corner — and GM2026
// culls per-view by instance position, so its Draw End (which paints the notification at
// fixed bottom-left SURFACE coords, ignoring x/y) never ran unless the camera happened to
// be near the corner. Pin the instance to the view centre so it can never be culled.
x = __view_get( e__VW.XView, 0 ) + 160;
y = __view_get( e__VW.YView, 0 ) + 120;

if (fadeout == 0) {
    if(!visible) alarm[0]++; //added
    if (offset > 0) offset -= 1;
} else if (offset < 30) {
    offset += 1;
} else {
    instance_destroy();
    global.gotolog = -1;
}

