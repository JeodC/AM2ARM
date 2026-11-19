/// @description  isCollisionUpLeft()
function isCollisionUpLeft() {
	// Detect a rising left corner that can be cleared by shifting toward an unobstructed center.
	var yoff;
	if (yVel <= 0) {
	    yoff = -1 + yVel * 2;
	    if (collision_line(x, y + collisionBoundsOffsetTopY, x, y + collisionBoundsOffsetTopY + yoff, oSolid, true, true) == noone) {
	        if (collision_line(x + collisionBoundsOffsetLeftX, y + collisionBoundsOffsetTopY, x + collisionBoundsOffsetLeftX, y + collisionBoundsOffsetTopY + yoff, oSolid, true, true) > 0) return 1;
	    }
	}
	return 0;



}
