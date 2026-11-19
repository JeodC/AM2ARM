/// @description get_ground_tile(x, y);
/// @param x
/// @param  y
function get_ground_tile(argument0, argument1) {
	// Returns the tile from one of the ground layers, or -1 if none found.

	var xx = argument0,
	    yy = argument1;

	var tile = tile_layer_find(-100, xx, yy);
	if(tile == -1) tile = tile_layer_find(-90, xx, yy);
	if(tile == -1) tile = tile_layer_find(-99, xx, yy);
	if(tile == -1) tile = tile_layer_find(-101, xx, yy);
	if(tile == -1) tile = tile_layer_find(-105, xx, yy);
	if(tile == -1) tile = tile_layer_find(-110, xx, yy);
	if(tile == -1) tile = tile_layer_find(-120, xx, yy);

	return tile;



}

// The burrowing enemy only needs coverage at four points, not tile IDs. Resolve
// them together instead of enumerating a dense asset layer for each point.
// Read live geometry on every call so destroyed, moved and scaled tiles retain
// the same behavior as get_ground_tile; no room-wide cache needs invalidation.
function ground_burrow_finished(_left, _right, _top, _bottom) {
    var _layers = layer_get_all(), _seen = 0;
    var _min_x = min(_left, _right), _max_x = max(_left, _right);
    var _min_y = min(_top, _bottom), _max_y = max(_top, _bottom);
    for (var _i = 0; _i < array_length(_layers); ++_i) {
        var _depth = layer_get_depth(_layers[_i]);
        if (_depth != -100 && _depth != -90 && _depth != -99 && _depth != -101
            && _depth != -105 && _depth != -110 && _depth != -120) continue;
        var _elements = layer_get_all_elements(_layers[_i]);
        for (var _j = 0; _j < array_length(_elements); ++_j) {
            var _tile = _elements[_j];
            if (layer_get_element_type(_tile) != layerelementtype_tile) continue;
            var _sx = layer_tile_get_xscale(_tile), _x0 = layer_tile_get_x(_tile);
            if (_sx >= 0 && _x0 > _max_x) continue;
            var _sy = layer_tile_get_yscale(_tile), _y0 = layer_tile_get_y(_tile);
            if (_sy >= 0 && _y0 > _max_y) continue;
            var _region = layer_tile_get_region(_tile);
            var _x1 = _x0 + _sx * _region[2], _y1 = _y0 + _sy * _region[3];
            if (_x0 > _x1) { var _swap_x = _x0; _x0 = _x1; _x1 = _swap_x; }
            if (_y0 > _y1) { var _swap_y = _y0; _y0 = _y1; _y1 = _swap_y; }
            if (_max_x < _x0 || _min_x >= _x1 || _max_y < _y0 || _min_y >= _y1) continue;
            var _hit_left = _left >= _x0 && _left < _x1;
            var _hit_right = _right >= _x0 && _right < _x1;
            if (_top >= _y0 && _top < _y1) {
                if (_hit_left) _seen |= 1;
                if (_hit_right) _seen |= 2;
                if ((_seen & 3) == 3) return true;
            }
            if (_bottom >= _y0 && _bottom < _y1) {
                if (_hit_left) _seen |= 4;
                if (_hit_right) _seen |= 8;
            }
        }
    }
    return (_seen & 12) != 12;
}
