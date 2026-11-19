/// @description  mus_current_fadeout(sound)
function mus_current_fadeout() {
	// Fade the current area track to silence without immediately stopping playback.
	if (audio_is_playing(oMusicV2.currentbgm)) audio_sound_gain(oMusicV2.currentbgm, 0, 3000);



}
