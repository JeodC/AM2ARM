/// @description  debug_draw_var2(offset, kind, text)
function debug_draw_var2(argument0, argument1, argument2) {
	// Draw one debug row, using yellow for headings and gray for zero-valued flags.
	draw_set_font(fontMenuSmall);
	draw_set_alpha(1);
	draw_set_color(c_black);
	draw_text(argument2 + 1, 10 + i * 8 + 1, string_hash_to_newline(argument0));
	draw_set_color(c_white);
	if (string(argument1) == "") draw_set_color(c_yellow);
	if (string(argument1) == "0") draw_set_color(c_gray);
	draw_text(argument2, 10 + i * 8, string_hash_to_newline(argument0));
	i += 1;



}
