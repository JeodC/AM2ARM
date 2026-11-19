/// @description  sv_add_unlocks()
function sv_add_unlocks() {
	var list, str_list;
	list = ds_list_create();
	// Serialize shared unlock flags for indices 0 through 49 in their stored order.
	i = 0;
	repeat (50) {
	    ds_list_add(list, global.unlock[i]);
	    i += 1;
	}
	str_list = ds_list_write(list);
	ds_list_clear(list);
	return str_list;



}
