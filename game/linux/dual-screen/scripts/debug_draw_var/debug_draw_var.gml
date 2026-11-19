/// @description  debug_draw_var(name, value)
function debug_draw_var(argument0, argument1) {
	// Append a labeled value to the calling debug display's row counter.
	draw_set_font(fontMenuSmall);
	draw_set_alpha(1);
	draw_text_shadow(2, 24 + i * 8, argument0 + string(argument1));
	i += 1;



}
