/// @description  sv6_add_monsters()
function sv6_add_monsters() {
	var list, str_list;
	list = ds_list_create();
	// Serialize Metroid defeat flags for indices 0 through 99 in their stored order.
	i = 0;
	repeat (100) {
	    ds_list_add(list, global.metdead[i]);
	    i += 1;
	}
	str_list = ds_list_write(list);
	ds_list_clear(list);
	return str_list;



}
