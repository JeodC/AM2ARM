/// @description  init_event_object(event_id)
function init_event_object(argument0) {
	// Bind this object to a saved event and remove it when that event is already completed.
	event = argument0;
	if (global.event[argument0] > 0) instance_destroy();



}
