/// @description  pal_swap_set(palette_sprite_or_surface, palette_index, is_surface)
// Retro Palette Swapper by PixelatedPope, MIT License
// (https://github.com/PixelatedPope/RetroPaletteSwapper). Palette index 0 means
// "no swap". Callers reset with shader_reset() after drawing.
function pal_swap_set(_pal_sprite, _pal_index, _is_surface) {
	if (_pal_index == 0) exit;
	// Unloaded palette (-1): draw unswapped instead of crashing — GMS1.4 was
	// this lenient, and callers don't all guard (e.g. Metroid draw events).
	if (_pal_sprite < 0) exit;
	var _swapper = global.retro_pal_swapper;
	shader_set(_swapper.shader);

	if (!_is_surface) {
		// Sprite-based palette: respect its placement on the texture page.
		var _tex = sprite_get_texture(_pal_sprite, 0),
		    _uvs = sprite_get_uvs(_pal_sprite, 0);
		texture_set_stage(_swapper.u_texture, _tex);

		var _texel_x = texture_get_texel_width(_tex),
		    _texel_y = texture_get_texel_height(_tex);
		shader_set_uniform_f(_swapper.u_texel_size, _texel_x, _texel_y);
		shader_set_uniform_f(_swapper.u_uvs, _uvs[0] + _texel_x * 0.5, _uvs[1] + _texel_y * 0.5, _uvs[2], _uvs[3]);
		shader_set_uniform_f(_swapper.u_index, _pal_index);
	} else {
		// Surface-based palette: the surface is its own texture, UVs span 0..1.
		var _tex = surface_get_texture(_pal_sprite);
		texture_set_stage(_swapper.u_texture, _tex);

		var _texel_x = texture_get_texel_width(_tex),
		    _texel_y = texture_get_texel_height(_tex);
		shader_set_uniform_f(_swapper.u_texel_size, _texel_x, _texel_y);
		shader_set_uniform_f(_swapper.u_uvs, _texel_x * 0.5, _texel_y * 0.5, 1.0 + _texel_x * 0.5, 1.0 + _texel_y * 0.5);
		shader_set_uniform_f(_swapper.u_index, _pal_index);
	}
}
