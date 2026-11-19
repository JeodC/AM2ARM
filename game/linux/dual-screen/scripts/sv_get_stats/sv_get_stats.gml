/// @description  sv_get_stats()
function sv_get_stats(argument0) {
	// Read this save section into shared statistics at indices 0 through 99.
	list = ds_list_create();
	ds_list_read(list, base64_decode(file_text_read_string(argument0)));
	i = 0;
	j = 0;
	repeat (100) {
	    global.stat[j] = readline();
	    j += 1;
	}
	ds_list_clear(list);



}
