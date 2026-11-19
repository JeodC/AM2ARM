/// @description  sv6_add_eventsA2()
function sv6_add_eventsA2() {
	var list, str_list;
	list = ds_list_create();
	// Serialize world-event flags for indices 100 through 149 in their stored order.
	i = 100;
	repeat (50) {
	    ds_list_add(list, global.event[i]);
	    i += 1;
	}
	str_list = ds_list_write(list);
	ds_list_clear(list);
	return str_list;



}
