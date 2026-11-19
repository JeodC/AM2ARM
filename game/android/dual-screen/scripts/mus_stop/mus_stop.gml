/// @description  mus_stop(sound)
function mus_stop(argument0) {
	// Stop the requested music track if it is playing.
	if (audio_is_playing(argument0)) audio_stop_sound(argument0);



}
