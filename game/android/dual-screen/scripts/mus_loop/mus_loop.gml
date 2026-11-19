/// @description  mus_loop(sound)
function mus_loop(argument0) {
	// Start a looping track and make it the current area music when it is not already playing.
	if (!audio_is_playing(argument0)) {
	    oMusicV2.currentbgm = argument0;
	    var _voice = audio_play_sound(argument0, 1, true);
	    if (argument0 == musTitle) oControl.title_music_voice = _voice;
	    audio_sound_gain(argument0, global.opmusicvolume / 100, 0);
	}



}
