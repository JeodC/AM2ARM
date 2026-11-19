/// @description Draw a sprite with independent horizontal and vertical pixel blocks.
/// @param sprite
/// @param subimg
/// @param x
/// @param y
/// @param xscale
/// @param yscale
/// @param rot
/// @param color
/// @param alpha
/// @param xpixelscale
/// @param ypixelscale
/// @param extent
function draw_sprite_pixelated(_sprite, _frame, _x, _y, _xs, _ys, _angle, _color, _alpha, _px, _py, _extent) {
    if (_xs == 0 || _ys == 0 || _alpha <= 0) return;
    _px = max(_px, 0.0001);
    _py = max(_py, 0.0001);
    if (!shader_is_compiled(shSpritePixelate) || shader_current() != -1) {
        draw_sprite_pixelated_fallback(_sprite, _frame, _x, _y, _xs, _ys,
            _angle, _color, _alpha, _px, _py, _extent);
        return;
    }

    static _u_uv = shader_get_uniform(shSpritePixelate, "uTextureUv");
    static _u_bounds = shader_get_uniform(shSpritePixelate, "uDrawBounds");
    static _u_sprite = shader_get_uniform(shSpritePixelate, "uSprite");
    static _u_pixel = shader_get_uniform(shSpritePixelate, "uPixelScale");
    if (_frame < 0) _frame = image_index;
    _frame = floor(_frame) mod sprite_get_number(_sprite);
    var _uv = sprite_get_uvs(_sprite, _frame);
    var _w = sprite_get_width(_sprite) * _uv[6];
    var _h = sprite_get_height(_sprite) * _uv[7];
    if (_w <= 0 || _h <= 0 || _uv[2] <= _uv[0] || _uv[3] <= _uv[1]) return;
    var _ox = _uv[4] - sprite_get_xoffset(_sprite);
    var _oy = _uv[5] - sprite_get_yoffset(_sprite);

    // Quantize around the original sprite origin, as the previous centered
    // scratch surface did. Include complete blocks at the trimmed edges.
    var _x1 = _ox * _xs, _x2 = (_ox + _w) * _xs;
    var _y1 = _oy * _ys, _y2 = (_oy + _h) * _ys;
    var _left = max(floor(min(_x1, _x2) / _px), -_extent / 2) * _px;
    var _right = min(ceil(max(_x1, _x2) / _px), _extent / 2) * _px;
    var _top = max(floor(min(_y1, _y2) / _py), -_extent / 2) * _py;
    var _bottom = min(ceil(max(_y1, _y2) / _py), _extent / 2) * _py;
    if (_right <= _left || _bottom <= _top) return;

    var _co = lengthdir_x(1, _angle), _si = -lengthdir_y(1, _angle);
    var _filter = gpu_get_texfilter();
    gpu_set_texfilter(false);
    shader_set(shSpritePixelate);
    shader_set_uniform_f(_u_uv, _uv[0], _uv[1], _uv[2], _uv[3]);
    shader_set_uniform_f(_u_bounds, _left, _top, _right, _bottom);
    shader_set_uniform_f(_u_sprite, _ox, _oy, _w, _h);
    shader_set_uniform_f(_u_pixel, _px, _py, 1 / _xs, 1 / _ys);
    draw_primitive_begin_texture(pr_trianglestrip, sprite_get_texture(_sprite, _frame));
    draw_vertex_texture_colour(_x + _left * _co + _top * _si, _y - _left * _si + _top * _co, 0, 0, _color, _alpha);
    draw_vertex_texture_colour(_x + _right * _co + _top * _si, _y - _right * _si + _top * _co, 1, 0, _color, _alpha);
    draw_vertex_texture_colour(_x + _left * _co + _bottom * _si, _y - _left * _si + _bottom * _co, 0, 1, _color, _alpha);
    draw_vertex_texture_colour(_x + _right * _co + _bottom * _si, _y - _right * _si + _bottom * _co, 1, 1, _color, _alpha);
    draw_primitive_end();
    shader_reset();
    gpu_set_texfilter(_filter);
}

// Retain the cropped path for devices where this shader is unavailable.
function draw_sprite_pixelated_fallback(argument0, argument1, argument2, argument3, argument4, argument5, argument6, argument7, argument8, argument9, argument10, argument11) {

	var xx = argument2,
	    yy = argument3,
	    pixel_scale_x = argument9,
	    pixel_scale_y = argument10,
	    _cache_slot = effect_scratch_slot(argument11),
	    surf = effect_scratch_acquire(oControl.effect_cache, _cache_slot, argument11);

	// Every invocation replaces the scratch contents before drawing this sprite.
	// Switching targets flushes the preceding use before the image is reused.
	if (surface_exists(surf)) {
	    surface_set_target(surf);
	    draw_clear_alpha(c_black, 0);
	    draw_sprite_ext(argument0, argument1, surface_get_width(surf)/2, surface_get_height(surf)/2, (1/pixel_scale_x)*argument4, (1/pixel_scale_y)*argument5, 0, argument7, argument8);
	    surface_reset_target();
	}

	if (!surface_exists(surf)) return;

	// Reposition the surface so rotation keeps the enlarged sprite centered at the requested point.
	var surfx = xx - (lengthdir_x((surface_get_width(surf)/2*pixel_scale_x), argument6) - lengthdir_y((surface_get_height(surf)/2*pixel_scale_y), argument6)),
	    surfy = yy - (lengthdir_y((surface_get_width(surf)/2*pixel_scale_x), argument6) + lengthdir_x((surface_get_height(surf)/2*pixel_scale_y), argument6));

	// Keep the original pixel grid, but omit the empty border when enlarging it.
	// Full sprite bounds include every frame; one extra texel protects filtering.
	var _sx = argument4 / pixel_scale_x, _sy = argument5 / pixel_scale_y;
	var _x1 = surface_get_width(surf)/2 - sprite_get_xoffset(argument0) * _sx;
	var _y1 = surface_get_height(surf)/2 - sprite_get_yoffset(argument0) * _sy;
	var _x2 = _x1 + sprite_get_width(argument0) * _sx;
	var _y2 = _y1 + sprite_get_height(argument0) * _sy;
	var _left = clamp(floor(min(_x1, _x2)) - 1, 0, surface_get_width(surf));
	var _top = clamp(floor(min(_y1, _y2)) - 1, 0, surface_get_height(surf));
	var _right = clamp(ceil(max(_x1, _x2)) + 1, 0, surface_get_width(surf));
	var _bottom = clamp(ceil(max(_y1, _y2)) + 1, 0, surface_get_height(surf));
	if (_right > _left && _bottom > _top) {
	    surfx += lengthdir_x(_left * pixel_scale_x, argument6) - lengthdir_y(_top * pixel_scale_y, argument6);
	    surfy += lengthdir_y(_left * pixel_scale_x, argument6) + lengthdir_x(_top * pixel_scale_y, argument6);
	    draw_surface_general(surf, _left, _top, _right - _left, _bottom - _top,
	        surfx, surfy, pixel_scale_x, pixel_scale_y, argument6, c_white, c_white, c_white, c_white, 1);
	}

	if (_cache_slot < 0) surface_free(surf);



}
