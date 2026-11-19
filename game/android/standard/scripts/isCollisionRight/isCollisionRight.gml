/// @description  isCollisionRight(offset)
function isCollisionRight(argument0) {
	// Probe for solid terrain beside the right edge of the caller's collision rectangle.
	calculateCollisionBounds();
	if (collision_line(round(rb + argument0 - 1), round(tb), round(rb + argument0 - 1), round(bb - 1), oSolid, true, true) > 0) return 1;
	return 0;



}
