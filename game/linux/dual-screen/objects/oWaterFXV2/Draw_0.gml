if(surface_exists(mysurf)) {
    global.wave_height = global.nano_enabled ? 2 : (max(round(lerp(global.wave_height, floor((60-(fps-1))^1.5), 0.1)) - 1, 1)); // Lower is smoother.
    var height_top = min(y_bottom-y_top, global.wave_height);
    
    // Camera values stay fixed during this Draw event; reuse them per strip.
    var _water_view_y = __view_get( e__VW.YView, 0 );
    var _water_view_h = __view_get( e__VW.HView, 0 );
    if ((_water_view_y + _water_view_h) >= y) {
        var _water_view_x = __view_get( e__VW.XView, 0 );
        var _water_view_w = __view_get( e__VW.WView, 0 );
        if (world_draw_unused()) {
            yy = ceil(240 / global.wave_height) * global.wave_height;
            xx = AMP * sin(THETA + FREQ * (yy-global.wave_height) / y_bottom);
            exit;
        }
        if (water_draw_batch(_water_view_x,
            _water_view_y, _water_view_w + oControl.widescreen_space, height_top)) exit;
        // Offset successive strips by a sine wave to make the submerged scene ripple.
        for (yy = 0; yy < 240; yy += global.wave_height) {
            xx = AMP * sin(THETA + FREQ * yy / y_bottom);
            if (yy >= y_top) {
                draw_surface_part_ext(mysurf, 0, yy, _water_view_w + oControl.widescreen_space, global.wave_height, _water_view_x + xx - (oControl.widescreen_space/2), _water_view_y + yy, 1, 1, -1, 0.2);
                if((yy-y_top) < global.wave_height) draw_surface_part_ext(mysurf, 0, y_top, _water_view_w + oControl.widescreen_space, yy-y_top, _water_view_x + xx - (oControl.widescreen_space/2), _water_view_y + y_top, 1, 1, -1, 0.2);
            } 
        }
        if(height_top < global.wave_height) draw_surface_part_ext(mysurf, 0, y_top, _water_view_w + oControl.widescreen_space, height_top, _water_view_x + xx - (oControl.widescreen_space/2), y, 1, 1, -1, 0.2);
    }
}

