/// @description Relocate Septoggs?
function scr_septoggs_67() {
	//Septoggs cannot be destroyed. GM will throw an error

	// Check for Space Jump or Speed Booster in the collected-item flags.
	if (global.item[6] == 1 || global.item[7] == 1) return true;
	else return false;



}
