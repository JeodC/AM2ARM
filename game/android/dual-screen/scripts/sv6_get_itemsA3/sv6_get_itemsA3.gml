/// @description  sv6_get_itemsA3()
function sv6_get_itemsA3(argument0) {
	// Read this save section into collected-item flags at indices 300 through 319.
	list = ds_list_create();
	ds_list_read(list, base64_decode(file_text_read_string(argument0)));
	i = 0;
	j = 300;
	repeat (20) {
	    global.item[j] = readline();
	    j += 1;
	}
	ds_list_clear(list);



}
