/// @description  isCollisionLadder()
function isCollisionLadder() {
	// Check whether the caller's collision rectangle overlaps a ladder.
	calculateCollisionBounds();
	return collision_rectangle(lb, tb, rb - 1, bb - 1, oLadder, true, true) > 0;



}
