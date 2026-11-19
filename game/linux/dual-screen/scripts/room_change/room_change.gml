/// @description  room_change(target_room, transition_type)
function room_change(argument0, argument1) {
	// Store the destination and transition style before capturing the outgoing image and entering the transition room.
	global.targetroom = argument0;
	global.transitiontype = argument1;
	with (oControl) {
	    // Loading can enter the next transition before any loading-room Draw event.
	    if (thor_enabled) {
	        thor_loading_transition = room == rm_loading;
	        // Only travel between area rooms keeps the lower map visible.
	        thor_keep_room_map = global.ingame
	            && string_copy(room_get_name(room), 1, 4) == "rm_a"
	            && string_copy(room_get_name(argument0), 1, 4) == "rm_a";
	    }

	    // Door fades draw the GPU surface directly; menus retain a recovery copy.
	    screen_capture_recovery = !(os_type == os_linux
	        && (global.transitiontype == 0 || global.transitiontype == 1));
	    event_user(3);
	    screen_capture_recovery = true;
	    fadedone = 0;
	}
	room_goto(rm_transition);



}
