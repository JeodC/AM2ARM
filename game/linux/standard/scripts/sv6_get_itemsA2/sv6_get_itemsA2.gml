/// @description  sv6_get_itemsA2()
function sv6_get_itemsA2(argument0) {
	// Read this save section into collected-item flags at indices 200 through 219.
	list = ds_list_create();
	ds_list_read(list, base64_decode(file_text_read_string(argument0)));
	i = 0;
	j = 200;
	repeat (20) {
	    global.item[j] = readline();
	    j += 1;
	}
	ds_list_clear(list);



}
