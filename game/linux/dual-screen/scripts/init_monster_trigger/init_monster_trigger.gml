/// @description  init_monster_trigger(met_id, facing)
function init_monster_trigger(argument0, argument1) {
	// Remove the encounter trigger when its saved Metroid ID is already defeated.
	if (global.metdead[argument0] == 1) {
	    instance_destroy();
	    exit;
	}
	myid = argument0;
	facing = argument1;
	image_xscale = facing;



}
