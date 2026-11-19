/// @description  mus_intro_fanfare()
function mus_intro_fanfare() {
	// Stop existing audio, play the arrival fanfare and schedule the area-music check.
	sfx_stop_all();
	mus_play_once(musFanfare);
	with (oMusicV2) alarm[0] = 60;



}
