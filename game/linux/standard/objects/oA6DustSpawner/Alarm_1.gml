var x1, y1, x2, y2;

repeat (15) {
    x1 = max(0, __view_get( e__VW.XView, 0 ) - 64 - (oControl.widescreen_space/2));
    y1 = max(0, __view_get( e__VW.YView, 0 ) - 64);
    x2 = min(room_width, __view_get( e__VW.XView, 0 ) + __view_get( e__VW.WView, 0 ) + 64 + (oControl.widescreen_space/2));
    y2 = min(room_height, __view_get( e__VW.YView, 0 ) + __view_get( e__VW.HView, 0 ) + 64);
    dust = instance_create(irandom_range(x1, x2), irandom_range(y1, y2), oA6Dust);
}

