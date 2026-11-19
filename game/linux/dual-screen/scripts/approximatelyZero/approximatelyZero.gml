/// @description  approximatelyZero(value)
function approximatelyZero(argument0) {
	// Treat tiny residual motion as stopped when the movement code settles its velocities.
	if (argument0 > -0.1 && argument0 < 0.1) {
	    return 1;
	} else return 0;



}
