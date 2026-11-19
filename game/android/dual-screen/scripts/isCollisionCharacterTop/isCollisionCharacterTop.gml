/// @description  isCollisionCharacterTop(offset)
function isCollisionCharacterTop(argument0) {
	// From a solid instance, check whether the player's feet reach its top.
	oCharacter.tempId = id;
	with (oCharacter) {
	    calculateCollisionBounds();
	    if (collision_line(round(lb), round(bb + argument0 - 1), round(rb - 1), round(bb + argument0 - 1), tempId, true, true) > 0) return 1;
	}
	return 0;



}
