/// @description  copy_save(from, to)
function copy_save(argument0, argument1) {
	// Replace the destination slot, refresh its menu details and flash the copied slot.
	file1 = "save" + string(argument0 + 1);
	file2 = "save" + string(argument1 + 1);
	if (file_exists(file2)) file_delete(file2);
	file_copy(file1, file2);
	with (oGameSelMenu) event_user(2);
	saveslot_flash(argument1);

	if (file_exists("random" + string(argument1 + 1) + ".ini"))
	{
	    //This is only here for old file cleanup.
	    file_delete("random" + string(argument1 + 1) + ".ini");
	}
	// Keep the older companion data file aligned with the copied slot when it exists.
	if (file_exists("save" + string(argument1 + 1) + ".dat"))
	{
	    file_delete("save" + string(argument1 + 1) + ".dat");
	} 
	if (file_exists("save" + string(argument0 + 1) + ".dat")) 
	{ 
	    file_copy("save" + string(argument0 + 1) + ".dat", "save" + string(argument1 + 1) + ".dat");
	}




}
