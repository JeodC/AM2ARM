/// @description  mus_play_once(sound)
function mus_play_once(argument0) {
	// Start this one-time music cue at music volume if it is not already playing.
	if (!audio_is_playing(argument0)) {
	    audio_play_sound(argument0, 1, false);
	    audio_sound_gain(argument0, global.opmusicvolume / 100, 0);
	}



}
