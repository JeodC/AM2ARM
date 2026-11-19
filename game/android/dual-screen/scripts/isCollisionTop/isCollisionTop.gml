/// @description  isCollisionTop(offset)
function isCollisionTop(argument0) {
	// Probe for solid terrain above the caller's configured collision rectangle.
	calculateCollisionBounds();
	if (collision_line(round(lb), round(tb - argument0), round(rb - 1), round(tb - argument0), oSolid, true, true) > 0) return 1;
	return 0;



}
