// A missing player surface still takes the original recovery path.
if (global.nano_enabled && world_draw_unused() && surface_exists(surf)) {
    draw_set_blend_mode(bm_normal);
    exit;
}
characterDrawEvent();

