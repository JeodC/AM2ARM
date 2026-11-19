application_surface_draw_enable(0);
draw_clear(c_black);

if (shader_on && global.shaders_compiled) set_8bit_shader();
/// Draw game surface
if(widescreen) {
    // used view_*port[0] instead of display* previously because Wanderer was supporting all ratios
    if (surface_exists(widescreen_surface)) {
        var _sharp = sharp_scale_begin(widescreen_surface, display_scale);
        // xShake/yShake are game-pixel amounts; unscaled they are 0-5 physical px and
        // imperceptible on high-DPI screens (the viewport jitter oQuake also does never
        // reaches the screen in widescreen mode - view 1 renders to its own surface).
        draw_surface_ext(widescreen_surface, displayx+xShake*display_scale, displayy+yShake*display_scale, display_scale, display_scale, 0, c_white, 1);
        sharp_scale_end(_sharp);
    }
} else {
    if (surface_exists(application_surface)) {
        var _sharp = sharp_scale_begin(application_surface, display_scale);
        draw_game_surface(displayx, displayy, display_scale);
        sharp_scale_end(_sharp);
    }
}



shader_reset();
