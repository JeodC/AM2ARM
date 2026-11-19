/// @description  set_monsterstate()
function set_monsterstate() {
	// This debug prompt changes a saved Metroid flag directly.
	global.metdead[get_integer("Monster Number...", 0)] = get_integer("Set To State...", 0);
	check_areaclear();



}
