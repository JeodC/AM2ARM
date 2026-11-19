/// @description  draw_map_surf(x, y)
function draw_map_surf(argument0, argument1) {
	// leaks all variables, repositions calling instance..?
	// Convert this map cell to its eight-pixel drawing position in the calling instance.
	x = (argument0 - 3) * 8;
	y = (argument1 - 3) * 8;
	mystr = string(global.map[argument0, argument1]);
	if (mystr != "0") {
	    // Decode top, right, bottom and left edges, then color, symbol and corner shape.
	    wallU = string_char_at(mystr, 1);
	    wallR = string_char_at(mystr, 2);
	    wallD = string_char_at(mystr, 3);
	    wallL = string_char_at(mystr, 4);
	    color = string_char_at(mystr, 5);
	    special = string_char_at(mystr, 6);
	    corner = string_char_at(mystr, 7);
	    draw_mapblock(x, y, wallU, wallR, wallD, wallL, color, special, global.dmap[argument0, argument1], corner);
	}



}
