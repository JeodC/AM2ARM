// Preserve the original sequence, including zero-alpha and repeated draws.
var _flash = flashing > 0 || (state == 1 && statetime > 240);
if (global.nano_enabled) {
    // The head and sparse trail retain the boost cue. Body segments keep
    // their original sprite and damage flash without a boost overlay.
    if (world_draw_unused()) {
        if (_flash) draw_set_blend_mode(bm_normal);
        exit;
    }
    draw_self();
    if (_flash) {
        draw_set_blend_mode(bm_add);
        draw_sprite_ext(sprite_index, -1, x, y, image_xscale, image_yscale,
            image_angle, c_white, min(1, flashing * 0.2));
        draw_set_blend_mode(bm_normal);
    }
    exit;
}
var _boost = oErisHead.boosting;
if (world_draw_unused()) {
    if (_flash || _boost) draw_set_blend_mode(bm_normal);
    exit;
}
draw_self();
if (_flash || _boost) draw_set_blend_mode(bm_add);
if (_flash) {
    repeat (2) {
        draw_sprite_ext(sprite_index, -1, x, y, image_xscale, image_yscale, image_angle, -1, flashing * 0.1);
    }
}
if (_boost) {
    var _timer = oErisHead.fxtimer;
    if (_timer == 0 || _timer == 1)
        draw_sprite_ext(sprite_index, -1, x, y, image_xscale, image_yscale, image_angle, c_green, 1.1 + _timer * 0.2);
    if (_timer == 2 || _timer == 3) {
        repeat (2) {
            draw_sprite_ext(sprite_index, -1, x, y, image_xscale, image_yscale, image_angle, c_yellow, 1);
            draw_sprite_ext(sprite_index, -1, x, y, image_xscale, image_yscale, image_angle, c_white, 1);
        }
    }
    if (_timer == 4 || _timer == 5) {
        repeat (2) {
            draw_sprite_ext(sprite_index, -1, x, y, image_xscale, image_yscale, image_angle, c_red, 1);
        }
    }
}
if (_flash || _boost) draw_set_blend_mode(bm_normal);
