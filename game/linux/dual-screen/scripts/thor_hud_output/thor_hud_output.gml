// HUD strip presentation, transitions and fallback composition.
// Runs in oControl scope. Keep render-target, alpha and blend-state handling explicit.
// See SOURCE-MAP.txt for event entry points and shared state ownership.

function thor_draw_artwork_status(_x, _y, _width) {
    if (thor_art_gpu()) return;
    if (!surface_exists(thor_art_surface) || thor_art_top_rows == 0) return;
    var _left = _x + (_width - thor_art_width * thor_art_scale) / 2;
    draw_surface_part_ext(thor_art_surface, 0, 0, thor_art_width, thor_art_top_rows,
        _left, _y, thor_art_scale, thor_art_scale, c_white, 1);
    thor_art_draw_title_layer(thor_art_surface, thor_art_title_layout);
}

function thor_draw_artwork_footer(_x, _y, _width) {
    if (thor_art_gpu()) return;
    if (!surface_exists(thor_art_surface) || thor_art_footer_rows == 0) return;
    var _left = _x + (_width - thor_art_width * thor_art_scale) / 2;
    draw_surface_part_ext(thor_art_surface, 0, 128 - thor_art_footer_rows, thor_art_width, thor_art_footer_rows,
        _left, thor_height - thor_art_footer_rows * thor_art_scale, thor_art_scale, thor_art_scale, c_white, 1);
    thor_art_draw_hint_layer(thor_art_surface, thor_art_hint_mask);
}

function thor_art_help() {
    var _top = floor(thor_height - 41 * thor_art_scale);
    var _height = floor(8 * thor_art_scale);
    thor_art_rect(-thor_pad, _top, thor_width, _height, make_color_rgb(8, 58, 8));
    port_draw_help_text(155, _top, thor_width - 16, _height);
}

// Keep HUD snapshots on their native grid. The map and menu page snapshots
// remain at their existing resolution and never contain a reduced HUD copy.
function thor_art_gpu() {
    return thor_enabled;
}

function thor_art_flash(_escape, _fade) {
    // Apply the same reactor glow in screen coordinates. Each temporary strip
    // clips the glow to its own band; health and icon pixels are never rescaled.
    var _matrix = matrix_get(matrix_world), _blend = gpu_get_blendmode_ext_sepalpha();
    for (var _band = 0; _band < 3; ++_band) {
        var _title_band = _band == 2;
        var _rows = _title_band ? (thor_art_output_title[2] > 0 ? 32 : 0)
            : (_band == 0 ? thor_art_output_top : thor_art_output_bottom);
        if (_rows == 0) continue;
        var _scratch = _title_band ? thor_art_flash_title : (_band == 0 ? thor_art_flash_top : thor_art_flash_bottom);
        if (surface_exists(_scratch) && (surface_get_width(_scratch) != thor_art_width || surface_get_height(_scratch) != _rows))
            surface_free(_scratch);
        if (!surface_exists(_scratch)) _scratch = surface_create(thor_art_width, _rows);
        if (_title_band) thor_art_flash_title = _scratch;
        else if (_band == 0) thor_art_flash_top = _scratch; else thor_art_flash_bottom = _scratch;
        var _source_y = _title_band ? 64 : (_band == 0 ? 0 : 128 - _rows);
        surface_set_target(_scratch);
        matrix_set(matrix_world, matrix_build_identity());
        gpu_set_blendmode_ext(bm_one, bm_zero);
        draw_clear_alpha(c_black, _title_band ? 0 : 1);
        draw_surface_part_ext(thor_art_output, 0, _source_y, thor_art_width, _rows, 0, 0, 1, 1, c_white, 1);
        var _left = (thor_width - thor_art_width * thor_art_scale) / 2;
        var _top = _band == 0 ? 0 : thor_height - _rows * thor_art_scale;
        var _scale = thor_art_scale;
        if (_title_band) {
            _scale *= thor_art_output_title[2] / max(1, thor_art_pixels);
            _left += thor_art_output_title[0] * thor_art_scale - thor_art_width * _scale / 2;
            _top = thor_art_output_title[1] * thor_art_scale - 16 * _scale;
        }
        matrix_set(matrix_world, matrix_build(-_left / _scale, -_top / _scale, 0,
            0, 0, 0, 1 / _scale, 1 / _scale, 1));
        gpu_set_blendmode_ext_sepalpha(bm_zero, bm_inv_src_alpha, bm_zero, bm_one);
        draw_set_color(c_black); draw_set_alpha(1 - _fade);
        draw_rectangle(0, 0, thor_width, thor_height, false);
        if (_title_band) {
            // Accumulate the light before masking it with the title's coverage.
            // This retains both the glow sprite's alpha and the glyph's alpha.
            surface_reset_target();
            if (!surface_exists(thor_art_flash_light)) thor_art_flash_light = surface_create(thor_art_width, 32);
            surface_set_target(thor_art_flash_light);
            draw_clear_alpha(c_black, 0);
        }
        gpu_set_blendmode(bm_add);
        draw_set_color(c_white); draw_set_alpha(1);
        if (!_escape.fadeout) {
            var _camera = widescreen ? 1 : 0;
            var _sx = thor_width / __view_get(e__VW.WView, _camera);
            var _sy = thor_height / __view_get(e__VW.HView, _camera);
            var _x = (_escape.x - __view_get(e__VW.XView, _camera)) * _sx;
            var _y = (_escape.y - __view_get(e__VW.YView, _camera)) * _sy;
            var _xs = _escape.image_xscale * _sx, _ys = _escape.image_yscale * _sy;
            var _sprite = _escape.sprite_index, _frame = _escape.image_index;
            draw_sprite_ext(_sprite, _frame, _x, _y, _xs, _ys, _escape.image_angle, c_white, _escape.image_alpha);
            draw_sprite_ext(_sprite, _frame, _x, _y, -_xs, _ys, _escape.image_angle, c_white, _escape.image_alpha);
            draw_sprite_ext(_sprite, _frame, _x, _y, -_xs, -_ys, _escape.image_angle, c_white, _escape.image_alpha);
            draw_sprite_ext(_sprite, _frame, _x, _y, _xs, -_ys, _escape.image_angle, c_white, _escape.image_alpha);
        }
        draw_set_alpha(clamp(_escape.whitealpha, 0, 1));
        draw_rectangle(0, 0, thor_width, thor_height, false);
        draw_set_alpha(1); surface_reset_target();
        matrix_set(matrix_world, matrix_build_identity());
        if (_title_band) {
            surface_set_target(_scratch);
            gpu_set_blendmode_ext_sepalpha(bm_dest_alpha, bm_one, bm_zero, bm_one);
            draw_surface(thor_art_flash_light, 0, 0);
            surface_reset_target();
        }
        surface_set_target(thor_art_output);
        gpu_set_blendmode_ext(bm_one, bm_zero);
        draw_surface(_scratch, 0, _source_y);
        surface_reset_target();
    }
    gpu_set_blendmode_ext_sepalpha(_blend[0], _blend[1], _blend[2], _blend[3]); matrix_set(matrix_world, _matrix);
    draw_set_color(c_white); draw_set_alpha(1);
}

function thor_art_finish(_old_alpha, _frontend, _escape) {
    var _retain = room == rm_transition && !thor_loading_transition;
    var _death = _frontend == THOR_FRONTEND_DEATH && room == rm_death && instance_exists(oDeathSequence);
    var _eligible = !thor_setup_needed
        && (_frontend == THOR_FRONTEND_GAMEPLAY || _death) && room != rm_loading;
    var _fade = !thor_keep_room_map ? thor_room_alpha : 1;
    if (room == rm_transition && instance_exists(oTransition))
        _fade = thor_keep_room_map ? 1 : 1 - clamp(oTransition.fade, 0, 1);
    if (_death) _fade = 1 - clamp(oDeathSequence.fade, 0, 1);
    thor_art_output_fade = clamp(_fade, 0, 1);
    // Retained transition/death images and reactor flashes always follow their
    // live path. Their pixels must never be reused for ordinary gameplay.
    if (!_eligible || _retain || _death) thor_art_output_key = [];
    if (!_eligible) {
        thor_art_output_hints = 0;
        thor_art_output_title = [0, 0, 0];
        thor_art_output_top = 0;
        thor_art_output_bottom = 0;
    } else if (!_retain && !_death) {
        if (!surface_exists(thor_art_output)) {
            thor_art_output = effect_surface_create(thor_art_width, 128);
            thor_art_output_key = [];
        }
        var _previous = _old_alpha > 0 && surface_exists(thor_art_previous);
        thor_art_output_hints = thor_art_hint_mask | (_previous ? thor_art_previous_hints : 0);
        thor_art_output_title = thor_art_top_rows > 0 ? thor_art_title_layout
            : (_previous ? thor_art_previous_title : [0, 0, 0]);
        var _key = [thor_art_generation, thor_art_width, thor_art_top_rows,
            thor_art_footer_rows, thor_art_output_title];
        var _hit = !_previous && _escape == noone
            && array_equals(_key, thor_art_output_key);
        if (!_hit) {
            thor_art_compose_output(_old_alpha, _previous);
            // Keep the existing independent snapshot on a hit. Transition and
            // reactor frames still invalidate it through the live path above.
            thor_art_output_key = !_previous && _escape == noone ? variable_clone(_key) : [];
        }
        if (_escape != noone) { thor_art_flash(_escape, thor_art_output_fade); thor_art_output_fade = 1; }
    }
    if (thor_art_gpu() && !thor_swap_active()) {
        var _has_output = surface_exists(thor_art_output);
        if (_has_output) surface_set_target(thor_art_output);
        if (os_type == os_linux) draw_flush();
        Thor_Hud(_has_output ? thor_art_width : 0, _has_output ? 128 : 0,
            thor_art_output_top, thor_art_output_bottom, thor_art_output_fade,
            thor_art_output_title[0], thor_art_output_title[1], thor_art_output_title[2], thor_art_output_hints);
        if (_has_output) surface_reset_target();
    }
}

function thor_art_fallback() {
    if (!surface_exists(thor_art_output)) return;
    var _world = matrix_get(matrix_world), _blend = gpu_get_blendmode_ext_sepalpha();
    surface_set_target(thor_surface);
    matrix_set(matrix_world, matrix_build_identity());
    gpu_set_blendmode_ext(bm_one, bm_inv_src_alpha);
    var _color = merge_color(c_black, c_white, thor_art_output_fade);
    var _left = (thor_width - thor_art_width * thor_art_scale) / 2;
    if (thor_art_output_top > 0)
        draw_surface_part_ext(thor_art_output, 0, 0, thor_art_width, thor_art_output_top,
            _left, 0, thor_art_scale, thor_art_scale, _color, 1);
    if (thor_art_output_bottom > 0)
        draw_surface_part_ext(thor_art_output, 0, 128 - thor_art_output_bottom, thor_art_width, thor_art_output_bottom,
            _left, thor_height - thor_art_output_bottom * thor_art_scale, thor_art_scale, thor_art_scale, _color, 1);
    thor_art_draw_title_layer(thor_art_output, thor_art_output_title, thor_art_output_fade);
    thor_art_draw_hint_layer(thor_art_output, thor_art_output_hints, thor_art_output_fade);
    surface_reset_target();
    matrix_set(matrix_world, _world); gpu_set_blendmode_ext_sepalpha(_blend[0], _blend[1], _blend[2], _blend[3]);
}

function thor_art_draw_primary(_x, _y, _scene_scale) {
    if (!surface_exists(thor_art_output)) return;
    // Match the Presentation's native strip compositor at the final physical
    // resolution. Folding this into the 320x240 map would shrink HUD lettering.
    var _pixels = max(1, floor(thor_width * _scene_scale / 177));
    var _left = _x + floor((thor_width * _scene_scale - thor_art_width * _pixels) / 2);
    var _bottom = _y + thor_height * _scene_scale;
    var _color = merge_color(c_black, c_white, thor_art_output_fade);
    gpu_set_blendmode_ext(bm_one, bm_inv_src_alpha);
    if (thor_art_output_top > 0) {
        draw_surface_part_ext(thor_art_output, 0, 0, thor_art_width, thor_art_output_top,
            _left, _y, _pixels, _pixels, _color, 1);
        var _title = thor_art_output_title, _scale = _title[2];
        if (_scale > 0) draw_surface_part_ext(thor_art_output, 0, 64, thor_art_width, 32,
            _left + round(_title[0] * _pixels - thor_art_width * _scale / 2),
            _y + round(_title[1] * _pixels - 16 * _scale), _scale, _scale, _color, 1);
    }
    if (thor_art_output_bottom > 0) {
        draw_surface_part_ext(thor_art_output, 0, 128 - thor_art_output_bottom,
            thor_art_width, thor_art_output_bottom, _left,
            _bottom - thor_art_output_bottom * _pixels, _pixels, _pixels, _color, 1);
        var _hint_scale = max(0.5, floor(_pixels / 2));
        var _ends = [floor(thor_art_width / 3) - 1, floor(thor_art_width * 2 / 3) - 1, thor_art_width];
        for (var _i = 0; _i < 3; ++_i) if ((thor_art_output_hints & (1 << _i)) != 0)
            draw_surface_part_ext(thor_art_output, _i * 32, 56, 32, 8,
                _left + (_ends[_i] - 2) * _pixels - 32 * _hint_scale,
                _bottom - 14 * _pixels, _hint_scale, _hint_scale, _color, 1);
    }
}

function thor_art_draw_hint_layer(_surface, _mask, _brightness = 1) {
    if (_mask == 0) return;
    var _pixels = max(1, thor_art_pixels);
    var _scale = thor_art_scale * max(0.5, floor(_pixels / 2)) / _pixels;
    var _left = (thor_width - thor_art_width * thor_art_scale) / 2;
    var _ends = [floor(thor_art_width / 3) - 1, floor(thor_art_width * 2 / 3) - 1, thor_art_width];
    for (var _i = 0; _i < 3; ++_i) if ((_mask & (1 << _i)) != 0)
        draw_surface_part_ext(_surface, _i * 32, 56, 32, 8,
            _left + (_ends[_i] - 2) * thor_art_scale - 32 * _scale,
            thor_height - 14 * thor_art_scale, _scale, _scale,
            merge_color(c_black, c_white, _brightness), 1);
}

// Blend the current and previous HUD layers during menu transitions.
function thor_art_compose_output(_old_alpha, _previous) {
    var _blend = gpu_get_blendmode_ext_sepalpha(), _world = matrix_get(matrix_world);
    surface_set_target(thor_art_output);
    matrix_set(matrix_world, matrix_build_identity());
    draw_clear_alpha(c_black, 0);
    // Both inputs contain premultiplied pixels. Interpolate color and
    // coverage together so neither overlapping nor disappearing bands pop.
    gpu_set_blendmode_ext(bm_one, bm_one);
    var _alpha = _previous ? 1 - _old_alpha : 1;
    if (surface_exists(thor_art_surface) && (thor_art_top_rows > 0 || thor_art_footer_rows > 0))
        draw_surface_ext(thor_art_surface, 0, 0, 1, 1, 0, merge_color(c_black, c_white, _alpha), _alpha);
    if (_previous)
        draw_surface_ext(thor_art_previous, 0, 0, 1, 1, 0, merge_color(c_black, c_white, _old_alpha), _old_alpha);
    thor_art_output_top = max(thor_art_top_rows, _previous ? thor_art_previous_top : 0);
    thor_art_output_bottom = max(thor_art_footer_rows, _previous ? thor_art_previous_bottom : 0);
    surface_reset_target();
    matrix_set(matrix_world, _world); gpu_set_blendmode_ext_sepalpha(_blend[0], _blend[1], _blend[2], _blend[3]);
}
