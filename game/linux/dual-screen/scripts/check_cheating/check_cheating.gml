/// @description  check_cheating()
function check_cheating() {
	// This retained check marks the listed equipment as disallowed during gameplay and ends the game when c_id is set.
	if (global.ingame) {
	    if (global.spacejump != 0) c_id = 1;
	    if (global.screwattack != 0) c_id = 1;
	    if (global.speedbooster != 0) c_id = 1;
	    if (global.pbeam != 0) c_id = 1;
	    if (global.sbeam != 0) c_id = 1;
	    if (global.smissiles != 0) c_id = 1;
	    if (global.pbombs != 0) c_id = 1;
	}
	if (c_id != 0) game_end();



}
