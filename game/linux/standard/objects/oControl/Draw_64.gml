if (global.ingame) {
    if (surface_exists(gui_surface)) {
        if (global.ingame && displaygui && room != rm_transition && instance_exists(oCharacter)) {
            // GM2026: GUI canvas is pinned to window pixels (display_set_gui_size in Step),
            // so draw at the same window coords as the world composite — no
            // application_get_position() offset (that was for the default app-surface-
            // anchored GUI mapping, which we no longer use).
            var _sharp = sharp_scale_begin(gui_surface, display_scale);
            draw_surface_ext(gui_surface, displayx, displayy, display_scale, display_scale, 0, -1, 1);
            sharp_scale_end(_sharp);
        }
    }
}

//draw_text(4, 32, "Gamepad Index: " + string(global.gamepadIndex));
//draw_text(4, 48, "Control Type: " + string(global.controltype));


if (black > 0) {
    draw_set_alpha(1);
    draw_set_color(c_black);
    draw_rectangle(0, 0, display_get_width(), display_get_height(), false);
}

/* */
/*  */
