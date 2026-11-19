/// @description  remap_duplicate_xjoybtnmenu(index)
function remap_duplicate_xjoybtnmenu(argument0) {
	// Move the selected row's old gamepad menu binding to the first conflicting row before replacing it.
	if (global.opxjoybtn_menu1 == argument0) {
	    global.opxjoybtn_menu1 = get_control_xjoybtn(global.curropt);
	} else if (global.opxjoybtn_menu2 == argument0) {
	    global.opxjoybtn_menu2 = get_control_xjoybtn(global.curropt);
	}



}
