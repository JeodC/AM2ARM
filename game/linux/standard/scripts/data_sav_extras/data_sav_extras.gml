/// @description  data_sav_extras()
function data_sav_extras() {
	var list, str_list;
	list = ds_list_create();
	i = 0;

	// Persist Fusion earned through completion or the existing secret code.
	ds_list_add(list, global.mod_fusion_earned); // 1 used

	repeat (19) { // 20 total
	    ds_list_add(list, 0);
	    i += 1;
	}


	str_list = ds_list_write(list);
	ds_list_clear(list);
	return str_list;



}
