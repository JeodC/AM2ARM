/// @description  remap_duplicate_joybtnmenu(index)
function remap_duplicate_joybtnmenu(argument0) {
	// Move the selected row's old legacy-controller menu binding to the first conflicting row before replacing it.
	if (global.opjoybtn_menu1 == argument0) {
	    global.opjoybtn_menu1 = get_control_joyaxisbtn(global.curropt);
	} else if (global.opjoybtn_menu2 == argument0) {
	    global.opjoybtn_menu2 = get_control_joyaxisbtn(global.curropt);
	}



}
