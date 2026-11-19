/// @description  make_liquid(type, level, unknown, wave?, wspeed, wheight, layer)
function make_liquid(argument0, argument1, argument2, argument3, argument4, argument5, argument6) {
	// Set the liquid height used by gameplay and create the matching surface and screen filter.
	global.watertype = argument0;
	global.waterlevel = argument1;
	if (argument0 == 0) {
	    liquid = instance_create(0, global.waterlevel, oWater);
	    filter = instance_create(0, global.waterlevel, oWaterFXV2);
	}
	if (argument0 == 1) {
	    liquid = instance_create(0, global.waterlevel, oLavaSurface);
	    instance_create(0, global.waterlevel, oLavaBGFX);
	    filter = instance_create(0, global.waterlevel, oWaterFXV2);
	}
	if (argument2) liquid.alarm[0] = 1;
	// Configure surface waves independently of the liquid type.
	if (argument3) {
	    liquid.wave = 1;
	    liquid.wspeed = argument4;
	    liquid.wheight = argument5;
	} else {
	    liquid.wave = 0;
	    liquid.wspeed = 0;
	    liquid.wheight = 0;
	}
	// Place the surface and filter on the selected foreground depth.
	if (argument6 == 1) {
	    liquid.depth = -500;
	    filter.depth = -500;
	} else {
	    liquid.depth = -90;
	    filter.depth = -90;
	}



}
