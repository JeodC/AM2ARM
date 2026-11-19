var jawdir = direction + 270 + (image_yscale == -1) * 180;
if (world_draw_unused()) { draw_set_blend_mode(bm_normal); exit; }

draw_sprite_ext(sErisJaw, -1, x + lengthdir_x(jawoff, jawdir), y + lengthdir_y(jawoff, jawdir), 1, image_yscale, image_angle, -1, 1);
draw_sprite_ext(sErisHead, -1, x, y, 1, image_yscale, image_angle, -1, 1);

if (global.nano_enabled) {
    if (flashing > 0 || boosting) {
        var _nano_color = flashing > 0 ? c_white : (fxtimer < 2 ? c_green : (fxtimer < 4 ? c_yellow : c_red));
        var _nano_alpha = flashing > 0 ? min(1, flashing * 0.2) : 0.65;
        draw_set_blend_mode(bm_add);
        draw_sprite_ext(sErisJaw, -1, x + lengthdir_x(jawoff, jawdir), y + lengthdir_y(jawoff, jawdir),
            1, image_yscale, image_angle, _nano_color, _nano_alpha);
        draw_sprite_ext(sErisHead, -1, x, y, 1, image_yscale, image_angle, _nano_color, _nano_alpha);
        draw_set_blend_mode(bm_normal);
    }
    exit;
}

// Flashing
if (flashing > 0) {
    draw_set_blend_mode(bm_add);
    repeat (2) {
        draw_sprite_ext(sErisJaw, -1, x + lengthdir_x(jawoff, jawdir), y + lengthdir_y(jawoff, jawdir), 1, image_yscale, image_angle, -1, flashing * 0.1);
        draw_sprite_ext(sErisHead, -1, x, y, 1, image_yscale, image_angle, -1, flashing * 0.1);
    }
    draw_set_blend_mode(bm_normal);
}

if (boosting) {
    draw_set_blend_mode(bm_add);
    if (fxtimer == 0 || fxtimer == 1) {
        draw_sprite_ext(sErisJaw, -1, x + lengthdir_x(jawoff, jawdir), y + lengthdir_y(jawoff, jawdir), 1, image_yscale, image_angle, c_green, 1.1 + fxtimer * 0.2);
        draw_sprite_ext(sErisHead, -1, x, y, 1, image_yscale, image_angle, c_green, 1.1 + fxtimer * 0.2);
    }
    if (fxtimer == 2 || fxtimer == 3) {
        repeat (2) {
            draw_sprite_ext(sErisJaw, -1, x + lengthdir_x(jawoff, jawdir), y + lengthdir_y(jawoff, jawdir), 1, image_yscale, image_angle, c_yellow, 1);
            draw_sprite_ext(sErisHead, -1, x, y, 1, image_yscale, image_angle, c_yellow, 1);
            draw_sprite_ext(sErisJaw, -1, x + lengthdir_x(jawoff, jawdir), y + lengthdir_y(jawoff, jawdir), 1, image_yscale, image_angle, c_white, 1);
            draw_sprite_ext(sErisHead, -1, x, y, 1, image_yscale, image_angle, c_white, 1);
        }
    }
    if (fxtimer == 4 || fxtimer == 5) {
        repeat (2) {
            draw_sprite_ext(sErisJaw, -1, x + lengthdir_x(jawoff, jawdir), y + lengthdir_y(jawoff, jawdir), 1, image_yscale, image_angle, c_red, 1);
            draw_sprite_ext(sErisHead, -1, x, y, 1, image_yscale, image_angle, c_red, 1);
        }
    }
    draw_set_blend_mode(bm_normal);
}


//debug
//draw_text(16, 16, string(speed));

