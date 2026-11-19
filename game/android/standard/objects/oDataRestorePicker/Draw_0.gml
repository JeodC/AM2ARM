draw_set_font(fontMenuSmall);
draw_set_halign(fa_center);
draw_set_color(c_black);
var _title = get_text("Misc", (state == "dest") ? "RestoreDest_Title" : "RestoreSource_Title");
if (state == "restart") _title = get_text("Misc", "RestoreDone");
draw_text(161, 22, string_hash_to_newline(_title));
draw_set_color(c_white);
draw_text(160, 21, string_hash_to_newline(_title));

if (state == "confirm") {
    draw_set_font(fontGUI2);
    var w = max(string_width(string_hash_to_newline(lblstr)),
                string_width(string_hash_to_newline(yesstr)),
                string_width(string_hash_to_newline(nostr))) + 10;
    draw_set_color(c_black);
    draw_set_alpha(0.85);
    draw_rectangle(160 - w / 2 - 4, 96, 160 + w / 2 + 4, 148, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_text(160, 102, string_hash_to_newline(lblstr));
    draw_set_color(confirm_sel == 0 ? c_white : c_dkgray);
    draw_text(160, 118, string_hash_to_newline(yesstr));
    draw_set_color(confirm_sel == 1 ? c_white : c_dkgray);
    draw_text(160, 132, string_hash_to_newline(nostr));
}
draw_set_halign(fa_left);
draw_set_color(c_white);
