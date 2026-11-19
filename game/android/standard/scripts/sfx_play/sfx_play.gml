/// @description  sfx_play(sound)
function sfx_play(argument0) {
	// Start the effect and apply the configured effects volume.
	audio_play_sound(argument0, 1, false);
	audio_sound_gain(argument0, global.opsoundvolume / 100, 0);



}
