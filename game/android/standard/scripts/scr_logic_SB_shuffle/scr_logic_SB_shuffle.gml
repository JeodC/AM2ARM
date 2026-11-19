function scr_logic_SB_shuffle() {
	// Draw a permission value from the Speed Booster list without consuming the entry.
	ds_list_shuffle(oControl.list_speedbooster);
	return ds_list_find_value(oControl.list_speedbooster, ds_list_size(oControl.list_speedbooster) - 1);



}
