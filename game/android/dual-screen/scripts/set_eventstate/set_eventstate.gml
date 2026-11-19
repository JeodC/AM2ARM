/// @description  set_eventstate()
function set_eventstate() {
	// This debug prompt changes a saved event flag directly.
	global.event[get_integer("Event Number...", 0)] = get_integer("Set To State...", 0);



}
