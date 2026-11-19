function scr_random_draw_pool() {
	// Take one remaining item from the shuffled pool so it cannot be assigned twice.
	var temp_item_number = ds_list_find_value(oControl.list_locations, ds_list_size(oControl.list_locations) - 1);
	ds_list_delete(oControl.list_locations, ds_list_size(oControl.list_locations) - 1);
	return temp_item_number;



}
