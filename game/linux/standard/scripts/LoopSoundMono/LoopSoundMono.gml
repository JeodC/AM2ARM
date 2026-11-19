/// @description  LoopSoundMono(sound)
function LoopSoundMono(argument0) {
	// Restart this effect as a loop after stopping its previous playback.
	sfx_stop(argument0);
	sfx_loop(argument0);



}
