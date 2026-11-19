/// @description  isCollisionMovingSolidBottom(offset)
function isCollisionMovingSolidBottom(argument0) {
	// Check for a moving solid immediately below the caller's collision rectangle.
	calculateCollisionBounds();
	if (collision_line(round(lb), round(bb + argument0 - 1), round(rb - 1), round(bb + argument0 - 1), oMovingSolid, true, true) > 0) return 1;
	return 0;



}
