/// @description  mus_current_fadein(sound)
function mus_current_fadein() {
	// Start the current area track if needed and fade it up from silence.
	if (!audio_is_playing(oMusicV2.currentbgm)) audio_play_sound(oMusicV2.currentbgm, 1, true);
	audio_sound_gain(oMusicV2.currentbgm, 0, 0);
	audio_sound_gain(oMusicV2.currentbgm, global.opmusicvolume / 100, 3000);



}
