/// @description  make_deep_water()
function make_deep_water() {
	// Place the water level above the room and create the deep-water rendering effects.
	global.watertype = 0;
	global.waterlevel = -100;
	instance_create(0, 0, oWater2);
	instance_create(0, 0, oWaterFXV2);



}
