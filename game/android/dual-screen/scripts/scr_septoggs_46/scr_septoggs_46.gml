/// @description Relocate Septoggs?
function scr_septoggs_46() {
	//Septoggs cannot be destroyed. GM will throw an error

	// Check for Hi-Jump or Space Jump in the collected-item flags.
	if (global.item[4] == 1 || global.item[6] == 1) return true;
	else return false;



}
