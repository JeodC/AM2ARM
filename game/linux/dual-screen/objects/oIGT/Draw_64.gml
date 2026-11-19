// GM2026: GUI canvas = window pixels (oControl Step pins it), so no application_get_position offset
if(room != rm_transition && instance_exists(oCharacter) && global.ingame && oControl.displaygui && global.opshowhud) {
    var _sharp = sharp_scale_begin(igt_surface, oControl.display_scale);
    draw_surface_ext(igt_surface, oControl.displayx, oControl.displayy, oControl.display_scale, oControl.display_scale, 0, -1, 1);
    sharp_scale_end(_sharp);
}

