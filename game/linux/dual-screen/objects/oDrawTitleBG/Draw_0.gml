draw_background_ext(bgAM2RTitle, oControl.mod_xcoordinate, oControl.mod_ycoordinate, 1, 1, 0, -1, image_alpha);

draw_set_alpha(image_alpha);
draw_set_font(fontMenuSmallDefault);
draw_set_halign(fa_right);
var _link_right = 320 + (oControl.widescreen_space / 2);
var _reddit_url = "reddit.com/r/AM2R";
var _blog_url = "metroid2remake.blogspot.com";
var _project_url = "github.com/PatchDev-AM2ARM/AM2ARM";
draw_rectangle_colour(_link_right - string_width(_reddit_url) - 1, 216, _link_right, 223, c_black, c_black, c_black, c_black, false);
draw_rectangle_colour(_link_right - string_width(_blog_url) - 1, 224, _link_right, 231, c_black, c_black, c_black, c_black, false);
draw_rectangle_colour(_link_right - string_width(_project_url) - 1, 232, _link_right, 239, c_black, c_black, c_black, c_black, false);
draw_set_alpha(1);
draw_text_colour(_link_right, 213, _reddit_url, -1, -1, -1, -1, image_alpha);
draw_text_colour(_link_right, 221, _blog_url, -1, -1, -1, -1, image_alpha);
draw_text_colour(_link_right, 229, _project_url, -1, -1, -1, -1, image_alpha);
draw_set_halign(fa_left);
draw_set_font(global.fontVersion);
draw_background_ext(bgVersion, 0-(oControl.widescreen_space/2), 0, string_width(string_hash_to_newline(global.am2r_version)) + 1, 1, 0, -1, image_alpha);
draw_text_colour(1-(oControl.widescreen_space/2), 1, string_hash_to_newline(global.am2r_version), -1, -1, -1, -1, image_alpha);

