draw_set_alpha(1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_font(fontGUI2);
draw_set_color(c_white);
draw_text(24, 42, path_label);
for (var _row = 0; _row < page_rows; ++_row) {
    var _index = scroll + _row;
    if (_index >= array_length(entries)) break;
    var _y = 66 + _row * 16;
    var _label = linux_folder_label(entries[_index].label, 256);
    if (_index == selected)
        draw_background_ext(bgOptionLine, 30, _y - 1, 260, 1, 0, make_color_rgb(160, 160, 160), 0.4);
    port_draw_menu_text(32, _y, _label, 256);
}
draw_set_font(fontGUI2);
draw_set_halign(fa_right);
draw_text(296, 196, string(selected + 1) + "/" + string(array_length(entries)));
draw_set_halign(fa_left);
draw_set_color(c_white);
