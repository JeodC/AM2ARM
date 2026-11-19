/// @description  platformCharacterIs()
function platformCharacterIs(argument0) {
	// Group player poses for movement rules; actual surface contact is checked separately.
	if (argument0 == ON_GROUND && (state == RUNNING || state == STANDING || state == DUCKING || state == BALL)) return 1;
	if (argument0 == IN_AIR && (state == JUMPING || state == FALLING || state == AIRBALL)) return 1;
	if (argument0 == ON_LADDER && state == CLIMBING) return 1;
	return 0;



}
