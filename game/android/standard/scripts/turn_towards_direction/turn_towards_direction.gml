/// @description  turn_towards_direction(direction, turnspeed)
function turn_towards_direction(argument0, argument1) {
	var wdir, turnspeed, tempdir;
	wdir = argument0;
	turnspeed = argument1;
	// Turn across the angle boundary when that gives the shorter route, stopping at the target direction.
	if (abs(wdir - direction) > 180) {
	    if (wdir > 180) {
	        tempdir = wdir - 360;
	        if (abs(tempdir - direction) > turnspeed) {
	            direction -= turnspeed;
	        } else direction = wdir;
	    } else {
	        tempdir = wdir + 360;
	        if (abs(tempdir - direction) > turnspeed) {
	            direction += turnspeed;
	        } else direction = wdir;
	    }
	} else if (abs(wdir - direction) > turnspeed) {
	    if (wdir > direction) {
	        direction += turnspeed;
	    } else direction -= turnspeed;
	} else direction = wdir;



}
