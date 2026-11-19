/// @description  mus_resume(sound)
function mus_resume(argument0) {
	// Continue a paused track from its saved playback position.
	if (audio_is_paused(argument0)) audio_resume_sound(argument0);



}
