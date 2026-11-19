/// @description  save_game(path)
function save_game(argument0) {
	// Write the current run, then remove the temporary item-swap file.
	sv6_save(argument0);
	//scr_rand_encrypt_write();
	if (file_exists(working_directory + "\\swap.ini")) file_delete(working_directory + "\\swap.ini");




    save_sync_saved(true);
}
