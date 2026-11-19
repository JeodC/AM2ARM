/// @description Relocate Septoggs?
function scr_septoggs_2468() {
	//Septoggs cannot be destroyed. GM will throw an error

	// Check for Spider Ball, Hi-Jump, Space Jump or Screw Attack in the collected-item flags.
	if (global.item[2] == 1 || global.item[4] == 1 || global.item[6] == 1 || global.item[8] == 1) return true;
	else return false;



}
