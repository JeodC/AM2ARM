/// @description  remap_duplicate_joyaxis()
function remap_duplicate_joyaxis(argument0) {
	// Move the selected row's old axis binding to the first conflicting row before replacing it.
	if (global.opjoybtn_xax == argument0) {
	    global.opjoybtn_xax = get_control_joyaxisbtn(global.curropt);
	} else if (global.opjoybtn_yax == argument0) {
	    global.opjoybtn_yax = get_control_joyaxisbtn(global.curropt);
	}



}
