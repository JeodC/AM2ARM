/// @description  set_itemstate()
function set_itemstate() {
	// This debug prompt changes a saved pickup flag directly.
	global.item[get_integer("Item Number...", 0)] = get_integer("Set To State...", 0);



}
