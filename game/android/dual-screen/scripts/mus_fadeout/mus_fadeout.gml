/// @description  mus_fadeout(sound)
function mus_fadeout(argument0) {
	// Fade this track to silence so the music cleanup can stop it later.
	if (audio_is_playing(argument0)) audio_sound_gain(argument0, 0, 3000);



}
