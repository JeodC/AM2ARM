/// @description  SetSpinJumpSound()
function SetSpinJumpSound() {
	var _old = spinjump_sound;
	// Choose the spin loop from Space Jump, Screw Attack and the water restriction.
	if (global.spacejump == 0 && global.screwattack == 0) spinjump_sound = sndSpinJump;
	if (global.spacejump == 1 && global.screwattack == 0) spinjump_sound = sndSpaceJump;
	if (global.spacejump == 0 && global.screwattack == 1) spinjump_sound = sndScrewAttack;
	if (global.spacejump == 1 && global.screwattack == 1) spinjump_sound = sndSpaceScrewAttack;
	if (inwater && global.currentsuit < 2) spinjump_sound = sndSpinJumpWater;
	// Stuck-loop fix: this runs every step, so when the medium changes mid-spin (e.g. a
	// wall cling right at the water surface) the variable switches, and every later
	// sfx_stop(spinjump_sound) targets the NEW sound — the old loop (sndSpinJumpWater)
	// would repeat forever. Stop the old loop the moment the variable changes.
	if (_old != spinjump_sound && audio_is_playing(_old)) audio_stop_sound(_old);



}
