/// @description  sv6_add_events()
function sv6_add_events() {
	var list, str_list;
	list = ds_list_create();
	// Serialize world-event flags for indices 0 through 349 in their stored order.
	i = 0;
	repeat (350) {
	    ds_list_add(list, global.event[i]);
	    i += 1;
	}
	str_list = ds_list_write(list);
	ds_list_clear(list);
	return str_list;



}
