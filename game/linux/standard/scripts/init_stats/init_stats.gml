/// @description  init_stats()
function init_stats() {
	// Initialize the persistent unlock, gallery, statistics and achievement arrays before loading saved values.
	global.mod_gamebeaten = 0;
	global.mod_fusion_unlocked = 0;
	global.mod_fusion_earned = 0;
	i = 50;
	repeat (50) {
	    i -= 1;
	    global.unlock[i] = 0;
	}
	i = 50;
	repeat (50) {
	    i -= 1;
	    global.gallery[i] = 0;
	}
	i = 100;
	repeat (100) {
	    i -= 1;
	    global.stat[i] = 0;
	}
	i = 100;
	repeat (100) {
	    i -= 1;
	    global.achievement[i] = 0;
	}



}

// Derive menu availability from persistent records, including imported progress.
function refresh_mode_unlocks() {
    global.mod_gamebeaten = global.unlock[0] == 1 || global.unlock[1] == 1 || global.unlock[2] == 1;
    global.mod_fusion_unlocked = global.mod_fusion_earned == 1;
}
