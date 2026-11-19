/// @description  sv6_get_eventsA5()
function sv6_get_eventsA5(argument0) {
	// Read this save section into world-event flags at indices 250 through 299.
	list = ds_list_create();
	ds_list_read(list, base64_decode(file_text_read_string(argument0)));
	i = 0;
	j = 250;
	repeat (50) {
	    global.event[j] = readline();
	    j += 1;
	}
	ds_list_clear(list);



}
