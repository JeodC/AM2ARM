/// @description  getIdCollisionLeft(offset)
function getIdCollisionLeft(argument0) {
	// Return the solid beside the left probe so callers can inspect the contacted instance.
	calculateCollisionBounds();
	return collision_line(round(lb - argument0), round(tb), round(lb - argument0), round(bb - 1), oSolid, true, true);



}
