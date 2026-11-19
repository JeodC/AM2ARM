/// @description  sv6_add_logs()
function sv6_add_trooper_logs() {
	var list, str_list;
	list = ds_list_create();
	// Serialize trooper-log unlocks for indices 0 through 7 in their stored order.
	i = 0;
	repeat (8) {
	    ds_list_add(list, global.trooperlog[i]);
	    i += 1;
	}
	str_list = ds_list_write(list);
	ds_list_clear(list);
	return str_list;



}
