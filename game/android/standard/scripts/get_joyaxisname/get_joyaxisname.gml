/// @description  get_joyaxisname(axis_id)
function get_joyaxisname(argument0) {
	// Give axis and POV bindings the translated labels used by the controller menu.
	if (argument0 == 0) return get_text("Buttons", "XAxis");
	if (argument0 == 1) return get_text("Buttons", "YAxis");
	if (argument0 == 2) return get_text("Buttons", "ZAxis");
	if (argument0 == 3) return get_text("Buttons", "RAxis");
	if (argument0 == 4) return get_text("Buttons", "UAxis");
	if (argument0 == 5) return get_text("Buttons", "VAxis");
	if (argument0 == 6) return get_text("Buttons", "POV"); // x-pov
	if (argument0 == 7) return get_text("Buttons", "POV"); // y-pov



}
