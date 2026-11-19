/// @description  goto_saveroom()
function goto_saveroom() {
	// This debug shortcut resolves a save-location key and enters its gameplay room.
	global.save_room = get_integer("Go to Save Room...", 0);
	set_start_location();
	room_goto(global.start_room);



}
