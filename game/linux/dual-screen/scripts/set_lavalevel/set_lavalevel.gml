/// @description  set_lavalevel()
function set_lavalevel() {
	// This debug prompt selects a lava progression stage and clears the current-area count.
	global.lavastate = get_integer("Set Lava Level...", 0);
	global.monstersarea = 0;



}
