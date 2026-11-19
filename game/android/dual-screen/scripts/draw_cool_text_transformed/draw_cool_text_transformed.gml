/// @description  draw_cool_text(x, y, text, outline_color, top_color, bottom_color, alpha, scale)
function draw_cool_text_transformed(argument0, argument1, argument2, argument3, argument4, argument5, argument6, argument7) {
	// Build an outlined text label using the requested scale and the calling instance's rotation.
	draw_set_alpha(argument6);
	draw_set_color(argument3);
	draw_text_transformed(argument0 + 1, argument1, string_hash_to_newline(argument2), argument7, argument7, image_angle);
	draw_text_transformed(argument0 - 1, argument1, string_hash_to_newline(argument2), argument7, argument7, image_angle);
	draw_text_transformed(argument0, argument1 + 1, string_hash_to_newline(argument2), argument7, argument7, image_angle);
	draw_text_transformed(argument0, argument1 - 1, string_hash_to_newline(argument2), argument7, argument7, image_angle);
	draw_text_transformed(argument0 + 1, argument1 + 1, string_hash_to_newline(argument2), argument7, argument7, image_angle);
	draw_text_transformed(argument0 + 1, argument1 - 1, string_hash_to_newline(argument2), argument7, argument7, image_angle);
	draw_text_transformed(argument0 - 1, argument1 + 1, string_hash_to_newline(argument2), argument7, argument7, image_angle);
	draw_text_transformed(argument0 - 1, argument1 - 1, string_hash_to_newline(argument2), argument7, argument7, image_angle);
	draw_text_transformed_colour(argument0, argument1, string_hash_to_newline(argument2), argument7, argument7, image_angle, argument4, argument4, argument5, argument5, argument6);
	draw_set_alpha(1);



}
