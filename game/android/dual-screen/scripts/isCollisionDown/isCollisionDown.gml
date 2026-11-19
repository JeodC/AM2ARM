/// @description  isCollisionDown()
function isCollisionDown() {
	// Return clear space below the caller, as a point test rather than a body overlap.
	if (position_meeting(x, y + 8, oSolid) == false) {
	    return 1;
	} else return 0;



}
