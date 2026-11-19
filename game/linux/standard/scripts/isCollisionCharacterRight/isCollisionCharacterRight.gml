/// @description  isCollisionCharacterRight(offset)
function isCollisionCharacterRight(argument0) {
	// From a solid instance, check whether the player's left edge reaches its right side.
	oCharacter.tempId = id;
	with (oCharacter) {
	    calculateCollisionBounds();
	    if (collision_line(round(lb - argument0), round(tb), round(lb - argument0), round(bb - 1), tempId, true, true) > 0) return 1;
	}
	return 0;



}
