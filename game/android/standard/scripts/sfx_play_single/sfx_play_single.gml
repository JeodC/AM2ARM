/// @description  sfx_play_single(sound)
function sfx_play_single(argument0) {
	// Prevents sound stacking?
	// Store the requested sound for Alarm 9 to stop and replay on the music object.
	oMusicV2.sound_id = argument0;
	oMusicV2.alarm[9] = 1;



}
