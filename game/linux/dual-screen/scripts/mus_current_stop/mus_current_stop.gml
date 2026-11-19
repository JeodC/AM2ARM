/// @description  mus_current_stop()
function mus_current_stop() {
	// Stop playback of the area track remembered by the music object.
	if (audio_is_playing(oMusicV2.currentbgm)) audio_stop_sound(oMusicV2.currentbgm);



}
