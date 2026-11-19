/// @description  monster_spawn_powerups(x, y, num_hp, num_missile)
function monster_spawn_powerups(argument0, argument1, argument2, argument3) {
	// Scatter health and missile refills around a defeated Metroid.
	repeat (argument2) instance_create(argument0 - 16 + random(32), argument1 - 16 + random(32), oHPickupBig);
	repeat (argument3) instance_create(argument0 - 16 + random(32), argument1 - 16 + random(32), oMPickup);
	// Add Super Missile refills when available, with separate Alpha and Gamma limits.
	if ((global.maxsmissiles > 0) && !instance_exists(oMAlpha)) {
	    if (((argument3 / 5) < 1) || instance_exists(oMGamma)) repeat (1) instance_create(argument0 - 16 + random(32), argument1 - 16 + random(32), oSMPickup);
	    else repeat floor(argument3 / 5) instance_create(argument0 - 16 + random(32), argument1 - 16 + random(32), oSMPickup);
	}



}
