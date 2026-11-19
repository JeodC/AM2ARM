/// @description  reset_hints()
function reset_hints() {
	// Clear the twenty hint flags so a new run can show those hints again.
	i = 0;
	repeat (20) {
	    global.hint[i] = 0;
	    i += 1;
	}



}
