/// @description  draw_game_surface(x, y, scale)
function draw_game_surface(argument0, argument1, argument2) {
	// Present the gameplay surface at the requested position and scale.
	draw_surface_ext(application_surface, argument0, argument1, argument2, argument2, 0, c_white, 1);
	// The alternate display effect combines horizontally offset red and cyan copies.
	if (global.opapril == 1) {
	    draw_set_color(c_black);
	    draw_set_alpha(1);
	    draw_rectangle(0, 0, display_get_width(), display_get_height(), false);
	    draw_set_blend_mode(bm_add);
	    draw_surface_ext(application_surface, argument0 - argument2 * 2, argument1, argument2, argument2, 0, c_red, 1);
	    draw_surface_ext(application_surface, argument0 + argument2 * 2, argument1, argument2, argument2, 0, c_aqua, 1);
	    draw_set_blend_mode(bm_normal);
	}



}

/// @description  sharp_scale_begin(surface, scale) — returns true if engaged
// Port fix: at fractional display scales (e.g. 4.5x on 1080p phones) plain
// nearest-neighbor renders uneven pixel rows — sawtooth "teeth" on every edge.
// Wrap the final surface blits with these to sample via shSharpPixel instead
// (texel-snapped + one-screen-pixel bilinear band). No-op at integer scales,
// and defers to any already-active shader (GameBoy mode owns its draw).
function sharp_scale_begin(_surf, _scale) {
	if (_scale == floor(_scale)) return false;
	if (shader_current() != -1) return false;
	shader_set(shSharpPixel);
	shader_set_uniform_f(oControl.sharp_pixel_tex_size, surface_get_width(_surf), surface_get_height(_surf));
	shader_set_uniform_f(oControl.sharp_pixel_scale, _scale);
	gpu_set_tex_filter(true);
	return true;
}

/// @description  sharp_scale_end(engaged)
function sharp_scale_end(_engaged) {
	if (!_engaged) return;
	gpu_set_tex_filter(false);
	shader_reset();
}

// Fill the available height/width while retaining the selected aspect ratio.
function android_display_scale(_width, _height) {
    return android_display_scale_for_window(_width, _height, window_get_width(), window_get_height());
}

// Reuse a single window snapshot within one display setup. Never retain these
// dimensions across frames: orientation, fullscreen and window size can change.
function android_display_scale_for_window(_width, _height, _window_width, _window_height) {
    var _sx = _window_width / _width;
    var _sy = _window_height / _height;
    // AM2R's 426px widescreen rounds a true 16:9 view down by less than one pixel.
    // Cover only that rounding difference; other aspect ratios remain fitted.
    if (abs(_window_width * _height / _window_height - _width) < 1) return max(_sx, _sy);
    return min(_sx, _sy);
}
