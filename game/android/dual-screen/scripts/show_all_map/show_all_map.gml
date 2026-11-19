/// @description  show_all_map()
function show_all_map() {
	// Reveal every discovery cell; only cells with map descriptions will have room artwork.
	i = 0;
	repeat (80) {
	    j = 0;
	    repeat (80) {
	        global.dmap[i, j] = 1;
	        j += 1;
	    }
	    i += 1;
	}



}
