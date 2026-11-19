/// @description  pal_swap_init_system(shader)
// Retro Palette Swapper by PixelatedPope, MIT License
// (https://github.com/PixelatedPope/RetroPaletteSwapper), trimmed to the
// standard path — the HTML5 fallback shaders are never needed on this port.
function pal_swap_init_system(_shader) {
	global.retro_pal_swapper = {
		shader: _shader,
		u_texel_size: shader_get_uniform(_shader, "u_pixelSize"),
		u_uvs: shader_get_uniform(_shader, "u_Uvs"),
		u_index: shader_get_uniform(_shader, "u_paletteId"),
		u_texture: shader_get_sampler_index(_shader, "u_palTexture"),
	};
}
