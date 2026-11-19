/// @description  PlaySoundMono(sound)
function PlaySoundMono(argument0) {
	// Restart the requested effect using the configured effects volume.
	audio_stop_sound(argument0);
	sfx_play(argument0);



}
