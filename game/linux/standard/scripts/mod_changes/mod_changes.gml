function mod_changes(argument0, argument1) {

	//if (global.mod_cheating == 1) { return abs(argument0); }
	// Keep this modifier at least as large as its supplied baseline.
	if (argument0 < argument1) { return argument1; }
	return argument0;



}
