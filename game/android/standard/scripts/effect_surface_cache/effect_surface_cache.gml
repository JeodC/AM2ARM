// Small 2D working surfaces. Never change the application's depth policy.
function effect_surface_create(_width, _height) {
    var _depth = surface_get_depth_disable();
    surface_depth_disable(true);
    var _surface = surface_create(_width, _height);
    surface_depth_disable(_depth);
    return _surface;
}

function effect_cache_create() {
    return {generation: 0, pixels: array_create(4, -1), trails: []};
}

function effect_scratch_slot(_size) {
    switch (_size) {
        case 16: return 0;
        case 32: return 1;
        case 64: return 2;
        case 128: return 3;
    }
    return -1;
}

function effect_scratch_acquire(_cache, _slot, _size) {
    // Unusual caller sizes remain temporary and cannot grow the cache.
    if (_slot < 0) return effect_surface_create(_size, _size);
    var _surface = _cache.pixels[_slot];
    if (!surface_exists(_surface)) {
        _surface = effect_surface_create(_size, _size);
        _cache.pixels[_slot] = _surface;
    }
    return _surface;
}

function effect_trail_acquire(_cache) {
    // A surface leaves the free list until this particular pose is finished.
    while (array_length(_cache.trails) > 0) {
        var _surface = array_pop(_cache.trails);
        if (surface_exists(_surface)) return _surface;
    }
    return effect_surface_create(64, 64);
}

function effect_trail_release(_cache, _generation, _surface) {
    if (!surface_exists(_surface)) return;
    // A paused/persistent room can retire old poses after the room cache reset.
    // They must not re-enter a newer generation's free list.
    if (_cache.generation == _generation && array_length(_cache.trails) < 16) {
        array_push(_cache.trails, _surface);
    } else {
        surface_free(_surface);
    }
}

function effect_cache_clear(_cache) {
    _cache.generation++;
    for (var _i = 0; _i < array_length(_cache.pixels); _i++) {
        if (surface_exists(_cache.pixels[_i])) surface_free(_cache.pixels[_i]);
        _cache.pixels[_i] = -1;
    }
    while (array_length(_cache.trails) > 0) {
        var _surface = array_pop(_cache.trails);
        if (surface_exists(_surface)) surface_free(_surface);
    }
}

// Four original mirrored draws, with a conservative full-quad rejection. Keep
// the two-pixel margin for fractional transforms and texture filtering edges.
function light_draw_quad(_sprite, _frame, _x, _y, _xs, _ys, _color, _alpha) {
    var _ox = sprite_get_xoffset(_sprite), _oy = sprite_get_yoffset(_sprite);
    var _rx = max(abs(_ox), abs(sprite_get_width(_sprite) - _ox)) * abs(_xs) + 2;
    var _ry = max(abs(_oy), abs(sprite_get_height(_sprite) - _oy)) * abs(_ys) + 2;
    if (_x + _rx < 0 || _x - _rx > 512 || _y + _ry < 0 || _y - _ry > 256) return;
    draw_sprite_ext(_sprite, _frame, _x, _y, _xs, _ys, 0, _color, _alpha);
    draw_sprite_ext(_sprite, _frame, _x, _y, -_xs, _ys, 0, _color, _alpha);
    draw_sprite_ext(_sprite, _frame, _x, _y, _xs, -_ys, 0, _color, _alpha);
    draw_sprite_ext(_sprite, _frame, _x, _y, -_xs, -_ys, 0, _color, _alpha);
}
