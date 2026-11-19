/// @description  link_surface_tile(x, y)
function link_surface_tile(argument0, argument1) {
	var tbg;
	// Use the surface tileset matching the time of day for this object's linked tile.
	if (global.timeofday == 0) tbg = tlSurface1;
	if (global.timeofday == 1) tbg = tlSurface1Twilight;
	if (global.timeofday == 2) tbg = tlSurface1Night;
	tileid = tile_add(tbg, argument0, argument1, 16, 16, x, y, -150);



}
