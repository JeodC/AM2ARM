/// @description  isCollisionPlatform()
function isCollisionPlatform() {
	// Check whether the caller overlaps a one-way platform, beyond a simple foot probe.
	calculateCollisionBounds();
	return collision_rectangle(lb, tb, rb - 1, bb - 1, oPlatform, true, true) > 0;



}
