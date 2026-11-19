/// @description  mus_get_main_song()
function mus_get_main_song() {
	// Choose the main-cave track from the run's time-of-day state.
	if (global.timeofday == 0) {
	    return musMainCave;
	} else return musMainCave2;



}
