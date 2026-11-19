/// @description  mus_play(sound)
function mus_play(argument0) {
	// Start this looping track at music volume if it is not already playing.
	if (!audio_is_playing(argument0)) {
	    audio_play_sound(argument0, 1, true);
	    audio_sound_gain(argument0, global.opmusicvolume / 100, 0);
	}



}
