/// @description  room_change(target_room, transition_type)
function room_change(argument0, argument1) {
	// Remember the destination and capture the current view before entering the transition room.
	global.targetroom = argument0;
	global.transitiontype = argument1;
	with (oControl) {

	    // Door fades draw the GPU surface directly; menus retain a recovery copy.
	    screen_capture_recovery = !(os_type == os_linux
	        && (global.transitiontype == 0 || global.transitiontype == 1));
	    event_user(3);
	    screen_capture_recovery = true;
	    fadedone = 0;
	}
	room_goto(rm_transition);



}
