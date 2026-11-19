/// @description  unlock_set(index)
function unlock_set(argument0) {
	// Record this extra once and persist the changed unlock state.
	if (global.unlock[argument0] == 0) {
	    global.unlock[argument0] = 1;
	    refresh_mode_unlocks();
	    save_stats();
	    if (!file_exists("extras.sav")) { save_stats2(); load_stats2(); } //without this you can't play random games without restart
	}



}
