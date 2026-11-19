/// @description data_load_extras()
function data_load_extras(argument0) {

	// Read the earned Fusion unlock from the extras records section.
	list = ds_list_create();
	ds_list_read(list, base64_decode(file_text_read_string(argument0)));
	i = 0;

	global.mod_fusion_earned = readline();
	if (is_undefined(global.mod_fusion_earned)) global.mod_fusion_earned = 0;
	refresh_mode_unlocks();

	ds_list_clear(list);



}
