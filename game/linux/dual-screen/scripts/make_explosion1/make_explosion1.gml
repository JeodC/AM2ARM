/// @description  make_explosion1(x, y)
function make_explosion1(argument0, argument1) {
	// Create an explosion animation and return it so the caller can adjust it.
	var expl;
	expl = instance_create(argument0, argument1, oFXAnimSpark);
	expl.image_speed = 0.5;
	expl.additive = 0;
	expl.sprite_index = sExpl1;
	return expl;



}
