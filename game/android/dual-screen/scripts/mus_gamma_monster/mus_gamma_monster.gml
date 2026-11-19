/// @description  mus_gamma_monster()
function mus_gamma_monster() {
	// Play the encounter sting and schedule the music object to check for the Gamma battle track.
	mus_stop_all();
	with (oMusicV2) alarm[2] = 60;
	mus_stop(musMonsterAppear);
	mus_play_once(musMonsterAppear);



}
