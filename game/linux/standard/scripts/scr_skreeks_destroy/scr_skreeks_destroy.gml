function scr_skreeks_destroy() {
	// Remove this room enemy after the progression threshold, using the later threshold for randomized runs.
	if (oControl.mod_randomgamebool == 1 && global.lavastate > 7) { instance_destroy(); }
	else if (oControl.mod_randomgamebool == 0 && global.lavastate > 6) instance_destroy();




}
