/// @description  sv6_get_items()
function sv6_get_items(argument0) {
	// Read this save section into collected-item flags at indices 0 through 349.
	list = ds_list_create();
	ds_list_read(list, base64_decode(file_text_read_string(argument0)));
	i = 0;
	j = 0;
	repeat (350) {
	    global.item[j] = readline();
	    j += 1;
	}
	ds_list_clear(list);



}
