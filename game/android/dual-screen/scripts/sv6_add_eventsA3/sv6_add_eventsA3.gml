/// @description  sv6_add_eventsA3()
function sv6_add_eventsA3() {
	var list, str_list;
	list = ds_list_create();
	// Serialize world-event flags for indices 150 through 199 in their stored order.
	i = 150;
	repeat (50) {
	    ds_list_add(list, global.event[i]);
	    i += 1;
	}
	str_list = ds_list_write(list);
	ds_list_clear(list);
	return str_list;



}
