/// @description  isCollisionMoveableSolidRight(offset)
function isCollisionMoveableSolidRight(argument0) {
	// Check for a moveable solid beside the caller's right edge.
	calculateCollisionBounds();
	if (collision_line(round(rb + argument0 - 1), round(tb), round(rb + argument0 - 1), round(bb - 1), oMoveableSolid, true, true) > 0) return 1;
	return 0;



}
