/// @description  sv6_get_eventsA1()
function sv6_get_eventsA1(argument0) {
	// Read this save section into world-event flags at indices 50 through 99.
	list = ds_list_create();
	ds_list_read(list, base64_decode(file_text_read_string(argument0)));
	i = 0;
	j = 50;
	repeat (50) {
	    global.event[j] = readline();
	    j += 1;
	}
	ds_list_clear(list);



}
