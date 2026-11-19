/// @description  sv_get_unlocks()
function sv_get_unlocks(argument0) {
	// Read this save section into shared unlock flags at indices 0 through 49.
	list = ds_list_create();
	ds_list_read(list, base64_decode(file_text_read_string(argument0)));
	i = 0;
	j = 0;
	repeat (50) {
	    global.unlock[j] = readline();
	    j += 1;
	}
	ds_list_clear(list);
	refresh_mode_unlocks();



}
