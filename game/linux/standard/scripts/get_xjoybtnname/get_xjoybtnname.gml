/// @description  get_xjoybtnname(gamepad_button)
function get_xjoybtnname(argument0) {
	// Choose button names from the configured controller layout.
	switch (oControl.mod_buttonsconfig)
	{
	    case 1: //PS
	        return scr_controller_ps(argument0)
	        break;
	    case 2:
	    case 3: //N
	        return scr_controller_N(argument0);
	        break;
	    default:
	        return scr_controller_xbox(argument0);
	        break;
	}



}
