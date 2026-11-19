/// @description Relocate Septoggs?
function scr_septoggs_26() {
	//Septoggs cannot be destroyed. GM will throw an error

	// Let room setup relocate the helper when Spider Ball or Space Jump has been collected.
	if (global.item[2] == 1 || global.item[6] == 1) return true;
	else return false;



}
