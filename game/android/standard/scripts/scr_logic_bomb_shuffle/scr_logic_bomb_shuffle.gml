function scr_logic_bomb_shuffle() {
	// Draw a permission value from the Bombs list without consuming the entry.
	ds_list_shuffle(oControl.list_bombs);
	return ds_list_find_value(oControl.list_bombs, ds_list_size(oControl.list_bombs) - 1);



}
