function scr_logic_PB_shuffle() {
	// Draw a permission value from the Power Bomb list without consuming the entry.
	ds_list_shuffle(oControl.list_powerbombs);
	var t = ds_list_find_value(oControl.list_powerbombs, ds_list_size(oControl.list_powerbombs) - 1);
	return t;



}
