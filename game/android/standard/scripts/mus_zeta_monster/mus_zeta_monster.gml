/// @description  mus_zeta_monster()
function mus_zeta_monster() {
	// Schedule the Zeta battle-music check after starting the encounter sting if needed.
	mus_stop_all();
	with (oMusicV2) alarm[3] = 60;
	if (!sfx_isplaying(musMonsterAppear)) mus_play_once(musMonsterAppear);



}
