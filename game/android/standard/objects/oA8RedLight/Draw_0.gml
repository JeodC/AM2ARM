if (global.nano_enabled && instance_exists(oLightEngine) && oLightEngine.nano_active) exit;
if (world_draw_unused()) { draw_set_blend_mode(bm_normal); exit; }
draw_set_blend_mode(bm_add);
draw_sprite_ext(sprite_index, -1, x, y, 1, 1, 0, -1, image_alpha);
draw_set_blend_mode(bm_normal);

