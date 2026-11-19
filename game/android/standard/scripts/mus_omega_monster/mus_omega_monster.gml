/// @description  mus_omega_monster()
function mus_omega_monster() {
	// Schedule the Omega battle-music check after starting the encounter sting if needed.
	mus_stop_all();
	with (oMusicV2) alarm[4] = 60;
	if (!sfx_isplaying(musMonsterAppear)) mus_play_once(musMonsterAppear);



}
