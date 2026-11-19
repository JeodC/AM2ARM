/// @description  create_log_label(text)
function create_log_label(argument0) {
	var l;
	// Insert a category heading and advance the calling menu's vertical row counter.
	l = instance_create(10 + (oControl.widescreen_space/3), 53 + j * 16, oMenuLabel);
	l.text = argument0;
	l.bg_width = 100;
	j += 1;
	return l;



}
