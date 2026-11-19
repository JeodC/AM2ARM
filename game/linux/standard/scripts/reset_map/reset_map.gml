/// @description  reset_map()
function reset_map() {
	writelog("Reset map start");
	// Clear both the fixed cell descriptions and their discovered state before loading a map.
	i = 0;
	repeat (80) {
	    j = 0;
	    repeat (80) {
	        writelog("Resetting " + string(i) + "," + string(j));
	        global.map[i, j] = "0";
	        global.dmap[i, j] = 0;
	        j += 1;
	    }
	    i += 1;
	}
	writelog("Reset map end");



}
