/// @description  draw_txt_2buttons(x, y, text, align, button1, button2, alpha)
function draw_txt_2buttons_log(argument0, argument1, argument2, argument3, argument4, argument5, argument6) {
	xoff = 0;
	yoff = 0;
	sep = 1;
	// Split the help text around two button placeholders before measuring the complete label.
	p_text1 = am2r_string_split(argument2, 0, "|");
	p_text2 = am2r_string_split(argument2, 1, "|");
	p_text3 = am2r_string_split(argument2, 2, "|");
	draw_set_font(fontMenuSmall2);
	if (p_text1 != "") {
	    w1 = string_width(string_hash_to_newline(p_text1));
	} else w1 = 0;
	w2 = string_width(string_hash_to_newline(p_text2));
	w3 = string_width(string_hash_to_newline(p_text3));
	b1 = sprite_get_width(get_button_sprite(argument4));
	b2 = sprite_get_width(get_button_sprite(argument5));
	draw_set_alpha(argument6);
	// Use button icons when available, otherwise insert the two keyboard binding labels.
	if ((global.controltype > 0) || (b1 > 0)) {
	    draw_set_halign(fa_left);
	    if (argument3 == 0) xoff -= round((w1 + w2 + w3 + b1 + b2 + sep * 4) / 2);
	    if (argument3 == 2) xoff -= round(w1 + w2 + w3 + b1 + b2 + sep * 4);
	    draw_set_color(make_colour_rgb(224, 248, 208)); // og c_white
	    draw_text_shadow_log(argument0 + xoff, argument1 + yoff, p_text1);
	    draw_sprite_ext(get_button_sprite(argument4), -1, argument0 + xoff + w1, argument1 + yoff + 6, 1, 1, 0, -1, argument6);
	    draw_text_shadow_log(argument0 + xoff + w1 + b1 + sep, argument1 + yoff, p_text2);
	    draw_sprite_ext(get_button_sprite(argument5), -1, argument0 + xoff + w1 + b1 + w2 + sep, argument1 + yoff + 6, 1, 1, 0, -1, argument6);
	    draw_text_shadow_log(argument0 + xoff + w1 + b1 + w2 + b2 + sep * 2, argument1 + yoff, p_text3);
	} else {
	    if (argument3 == 0) draw_set_halign(fa_center);
	    if (argument3 == 2) draw_set_halign(fa_right);
	    draw_set_color(make_colour_rgb(224, 248, 208)); // og c_white
	    draw_text_shadow_log(argument0 + xoff, argument1 + yoff, p_text1 + get_button_string(argument4) + p_text2 + get_button_string(argument5) + p_text3);
	}
	// Return drawing to full opacity and left alignment for following UI elements.
	draw_set_alpha(1);
	draw_set_halign(fa_left);



}
