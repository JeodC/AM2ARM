/// @description  getIdCollisionRight(offset)
function getIdCollisionRight(argument0) {
	// Return the solid beside the right probe so callers can inspect the contacted instance.
	calculateCollisionBounds();
	return collision_line(round(rb + argument0 - 1), round(tb), round(rb + argument0 - 1), round(bb - 1), oSolid, true, true);



}
