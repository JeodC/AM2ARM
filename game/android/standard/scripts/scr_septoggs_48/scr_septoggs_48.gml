/// @description Relocate Septoggs?
function scr_septoggs_48() {
	//Septoggs cannot be destroyed. GM will throw an error

	// Check for Hi-Jump or Screw Attack in the collected-item flags.
	if (global.item[4] == 1 || global.item[8] == 1) return true;
	else return false;



}
