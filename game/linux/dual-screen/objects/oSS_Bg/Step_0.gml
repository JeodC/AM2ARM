if (fadein) {
    if (image_alpha < 1) {
        image_alpha += 0.05;
    } else fadein = 0;
}
if(os_type == os_android && os_is_paused()) alarm[0]=1;
if (!surface_exists(oControl.screen_surface)) {
    oControl.screen_surface = surface_create(512+oControl.widescreen_space, 256);
    surface_set_target(oControl.screen_surface);
    draw_clear(c_black);
    surface_reset_target();
    // GM2026 fix: restore the frozen frame from raw pixels (written by oControl Other_13). The
    // old sprite_add("tempscr") PNG path loaded garbage on this Android runtime — the resumed
    // pause screen washed bright and lost the frame. buffer_load returns -1 on a miss, so no
    // file_exists() probe is needed (that probe is the "Failed to find asset" flood).
    if (oControl.tempscr_written) {
        var _memory_frame = os_type == os_linux;
        var _buf = _memory_frame ? oControl.tempscr_buffer : buffer_load("tempscr.buf");
        if (buffer_exists(_buf)) {
            buffer_seek(_buf, buffer_seek_start, 0);
            var _w = buffer_read(_buf, buffer_u32);
            var _h = buffer_read(_buf, buffer_u32);
            var _tmp = surface_create(_w, _h);
            buffer_set_surface(_buf, _tmp, 8);
            surface_set_target(oControl.screen_surface);
            draw_surface(_tmp, 0, 0);
            surface_reset_target();
            surface_free(_tmp);
            if (!_memory_frame) buffer_delete(_buf);
        }
    }
}

