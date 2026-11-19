/// @description  check_joybtn(joystick_id)
function check_joybtn(argument0) {
	// Find a pressed raw button for rebinding; mobile and Linux results use saved one-based numbering.
	if(os_type == os_windows) {
	    var i;
	    for(i = 0; i < joystick_buttons(argument0); i++) {
	        if(joystick_check_button(argument0, i)) {
	            return i;
	        }
	    }
	}
	else {
	    var i;
	    for(i = 0; i < gamepad_button_count(argument0); i++) {
	        if(gamepad_button_check(argument0, i)) { 
	            return i+1;
	        }
	    }
	}
	return 0;



}
