/// @description  isCollisionLeft(offset)
function isCollisionLeft(argument0) {
	// Probe for solid terrain beside the left edge of the caller's collision rectangle.
	calculateCollisionBounds();
	if (collision_line(round(lb - argument0), round(tb), round(lb - argument0), round(bb - 1), oSolid, true, true) > 0) return 1;
	return 0;



}
