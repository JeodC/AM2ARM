/// @description  scr_mouse_gui_y(mouse_y)
function scr_mouse_gui_y(argument0) {
	// Convert the pointer's vertical position from window or display pixels to GUI coordinates.
	if (os_type == os_windows || os_type == os_linux || os_type == os_macosx) {
	    return display_get_gui_height() * argument0 / window_get_height();
	} else return display_get_gui_height() * argument0 / display_get_height();



}
