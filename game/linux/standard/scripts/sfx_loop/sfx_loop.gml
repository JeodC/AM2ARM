/// @description  sfx_loop(sound)
function sfx_loop(argument0) {
	// Start a looping effect at the effects-volume setting and return its playback handle.
	var sid;
	sid = audio_play_sound(argument0, 1, true);
	audio_sound_gain(argument0, global.opsoundvolume / 100, 0);
	return sid;



}
