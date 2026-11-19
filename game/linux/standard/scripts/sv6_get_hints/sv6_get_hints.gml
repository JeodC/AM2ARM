/// @description  sv6_get_hints()
function sv6_get_hints(argument0) {
	// Read this save section into hint states at indices 0 through 49.
	list = ds_list_create();
	ds_list_read(list, base64_decode(file_text_read_string(argument0)));
	i = 0;
	j = 0;
	repeat (50) {
	    global.hint[j] = readline();
	    j += 1;
	}
	ds_list_clear(list);



}
