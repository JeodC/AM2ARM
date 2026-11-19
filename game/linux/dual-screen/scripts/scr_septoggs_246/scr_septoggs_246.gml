/// @description Relocate Septoggs?
function scr_septoggs_246() {
	//Septoggs cannot be destroyed. GM will throw an error

	// Let room setup relocate the helper when Spider Ball, Hi-Jump or Space Jump has been collected.
	if (global.item[2] == 1 || global.item[4] == 1 || global.item[6] == 1) {
	    return true;
	} else {
	    return false;
	}



}
