/// @description  spawn_many_powerups(region_x, region_y, region__width, region_height)
function spawn_many_powerups_tank(argument0, argument1, argument2, argument3) {
	// Scatter a large refill supply inside the specified rectangle, adding ammo types according to the conditions below.
	repeat (20) instance_create(argument0 + random(argument2), argument1 + random(argument3), oHPickupBig);
	if (global.maxmissiles > 0) {
	    repeat (20) instance_create(argument0 + random(argument2), argument1 + random(argument3), oMPickup);
	}
	if (global.maxsmissiles > 0) {
	    repeat (5) instance_create(argument0 + random(argument2), argument1 + random(argument3), oSMPickup);
	}
	if ((global.item[0] == 0 && global.maxpbombs > 0) || oControl.mod_insanitymode == 1) 
	{
	    repeat (5) instance_create(argument0 + random(argument2), argument1 + random(argument3), oPBPickup);
	}



}
