/// @description  remap_duplicate_kbkeymenu(key)
function remap_duplicate_kbkeymenu(argument0) {
	// Move the selected row's old keyboard menu binding to the first conflicting row before replacing it.
	if (global.opkeybtn_menu1 == argument0) {
	    global.opkeybtn_menu1 = get_control_keycode(global.curropt);
	} else if (global.opkeybtn_menu2 == argument0) {
	    global.opkeybtn_menu2 = get_control_keycode(global.curropt);
	}



}
