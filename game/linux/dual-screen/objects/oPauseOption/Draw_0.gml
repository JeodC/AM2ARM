draw_set_font(fontGUI2);
if (global.curropt == optionid) {
    w = min(256, string_width(string_hash_to_newline(label)));
    draw_background_ext(bgOptionLine, x - 2, y - 1, w + 4, 1, 0, make_color_rgb(160, 160, 160), 0.4);
}
if (enabled == 0) draw_set_alpha(0.5); else draw_set_alpha(1);
port_draw_menu_text(x, y, label, 256, color);
