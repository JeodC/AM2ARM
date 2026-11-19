/// @description  enemy_target_check()
function enemy_target_check(argument0, argument1) {
	// Acquire the player within range, optionally requiring the player to be in front of this enemy.
	target = 0;
	if (argument1 == 1 && distance_to_object(oCharacter) <= argument0) {
	    target = 1;
	}
	if (argument1 == 0 && distance_to_object(oCharacter) <= argument0) {
	    if (facing == 1 && x < oCharacter.x) target = 1;
	    if (facing == -1 && x > oCharacter.x) target = 1;
	}



}
