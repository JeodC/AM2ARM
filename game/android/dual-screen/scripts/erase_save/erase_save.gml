/// @description  erase_save()
function erase_save() {
	// Delete the selected slot and mark its menu entry empty.
	filename = "save" + string(global.saveslot + 1);
	file_delete(filename);
	with (oMenuSaveSlot) if (slot == global.saveslot) {
	    saveexists = 0;
	    smode = 0;
	}
	saveslot_flash(global.saveslot);

	// Remove the selected slot's older companion randomizer files as well.
	file_delete("random" + string(global.saveslot + 1) + ".ini");
	file_delete("save" + string(global.saveslot + 1) + ".dat");



}
