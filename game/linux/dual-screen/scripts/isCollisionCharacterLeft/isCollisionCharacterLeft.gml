/// @description  isCollisionCharacterLeft(offset)
function isCollisionCharacterLeft(argument0) {
	// From a solid instance, check whether the player's right edge reaches its left side.
	oCharacter.tempId = id;
	with (oCharacter) {
	    calculateCollisionBounds();
	    if (collision_line(round(rb + argument0 - 1), round(tb), round(rb + argument0 - 1), round(bb - 1), tempId, true, true) > 0) return 1;
	}
	return 0;



}
