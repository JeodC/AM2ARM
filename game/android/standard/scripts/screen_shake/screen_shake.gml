/// @description  screen_shake(duration, intensity)
function screen_shake(argument0, argument1) {
	// Create a camera-shake effect with no initial delay.
	var quake = instance_create(0, 0, oQuake);
	quake.delay = 0;
	quake.duration = argument0;
	quake.intensity = argument1;



}
