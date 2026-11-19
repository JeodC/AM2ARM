function make_maptile(argument0, argument1, argument2, argument3, argument4, argument5, argument6, argument7, argument8) {

	/// make_maptile(x, y, ...parameters)
	// This retained renderer builds discovered map cells from tiles instead of sprite draws.
	if (argument8 == 1) {
	    if (argument6 == "B") tile_add(tlMap, 0, 0, 8, 8, argument0, argument1, 0);
	    if (argument6 == "G") tile_add(tlMap, 8, 0, 8, 8, argument0, argument1, 0);
	    if (argument6 == "R") tile_add(tlMap, 16, 0, 8, 8, argument0, argument1, 0);
	    if (argument2 == "1") tile_add(tlMap, 8, 8, 8, 8, argument0, argument1, 0);
	    if (argument4 == "1") tile_add(tlMap, 24, 8, 8, 8, argument0, argument1, 0);
	    if (argument5 == "1") tile_add(tlMap, 0, 8, 8, 8, argument0, argument1, 0);
	    if (argument3 == "1") tile_add(tlMap, 16, 8, 8, 8, argument0, argument1, 0);
	    if (argument2 == "2") tile_add(tlMap, 8, 16, 8, 8, argument0, argument1, 0);
	    if (argument4 == "2") tile_add(tlMap, 24, 16, 8, 8, argument0, argument1, 0);
	    if (argument5 == "2") tile_add(tlMap, 0, 16, 8, 8, argument0, argument1, 0);
	    if (argument3 == "2") tile_add(tlMap, 16, 16, 8, 8, argument0, argument1, 0);
	    if (argument7 == "1") tile_add(tlMap, 0, 24, 8, 8, argument0, argument1, 0);
	    if (argument7 == "2") tile_add(tlMap, 8, 24, 8, 8, argument0, argument1, 0);
	    if (argument7 == "3") tile_add(tlMap, 16, 24, 8, 8, argument0, argument1, 0);
	    if (argument7 == "4") tile_add(tlMap, 24, 24, 8, 8, argument0, argument1, 0);
	    if (argument7 == "5") tile_add(tlMap, 0, 32, 8, 8, argument0, argument1, 0);
	}



}
