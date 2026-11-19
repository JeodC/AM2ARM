/// @description  create_log_obj(offset, label, text, pic, spacing, log_id)
function create_log_obj(argument0, argument1, argument2, argument3, argument4, argument5) {
	// Create a selectable log row carrying its title, body, picture and saved entry ID.
	l = instance_create(32, 64 + argument0 * argument4, oLog);
	l.label = argument1;
	l.ltext = argument2;
	l.lpic = argument3;
	l.optionid = argument0;
	l.logid = argument5;
	return l;



}
