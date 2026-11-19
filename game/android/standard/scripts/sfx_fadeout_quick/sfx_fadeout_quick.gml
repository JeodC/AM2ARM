/// @description  sfx_fadeout_quick(sound)
function sfx_fadeout_quick(argument0) {
	// Fade a playing effect to silence without immediately stopping it.
	if (audio_is_playing(argument0)) audio_sound_gain(argument0, 0, 1000);



}
