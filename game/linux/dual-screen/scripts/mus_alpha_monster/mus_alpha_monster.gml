/// @description  mus_alpha_monster()
function mus_alpha_monster() {
	// Play the encounter sting and schedule the music object to check for the Alpha battle track.
	mus_stop_all();
	with (oMusicV2) alarm[1] = 60;
	mus_stop(musMonsterAppear);
	mus_play_once(musMonsterAppear);



}
