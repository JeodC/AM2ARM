/// @description  isCollisionPlatformBottom(offset)
function isCollisionPlatformBottom(argument0) {
	// Check whether a one-way platform supports the caller at the requested offset.
	calculateCollisionBounds();
	if (collision_line(round(lb), round(bb + argument0 - 1), round(rb - 1), round(bb + argument0 - 1), oPlatform, true, true) > 0) return 1;
	return 0;



}
