/// @description  room_change(target_room, transition_type)
function room_change(argument0, argument1) {
	// Remember the destination and capture the current view before entering the transition room.
	global.targetroom = argument0;
	global.transitiontype = argument1;
	with (oControl) {

	    //show_debug_message("oControl commanded to generate screen_surface")
	    event_user(3);
	    fadedone = 0;
	}
	room_goto(rm_transition);



}
