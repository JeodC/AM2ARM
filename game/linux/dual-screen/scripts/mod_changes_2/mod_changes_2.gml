function mod_changes_2(argument0, argument1) {
	//Must check for absolute value here first. Could cheat otherwise.
	// Use a nonnegative modifier and cap it at the supplied baseline.
	var temp = abs(argument0);
	//if (global.mod_cheating == 1) { return temp; }
	if (temp > argument1) { return argument1; }
	return temp;



}
