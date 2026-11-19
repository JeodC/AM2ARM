/// @description  mus_pause(sound)
function mus_pause(argument0) {
	// Pause a playing track while preserving its playback position.
	if (audio_is_playing(argument0) && !audio_is_paused(argument0)) audio_pause_sound(argument0);



}
