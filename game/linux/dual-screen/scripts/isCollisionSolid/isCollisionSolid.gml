/// @description  isCollisionSolid()
function isCollisionSolid() {
	// Check whether the caller's collision rectangle overlaps solid terrain.
	calculateCollisionBounds();
	return collision_rectangle(lb, tb, rb - 1, bb - 1, oSolid, true, true) > 0;



}
