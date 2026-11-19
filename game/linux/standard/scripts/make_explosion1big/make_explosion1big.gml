/// @description  make_explosion1big(x, y)
function make_explosion1big(argument0, argument1) {
	// Create the large explosion animation and return it for further adjustment.
	var expl;
	expl = instance_create(argument0, argument1, oFXAnimSpark);
	expl.image_speed = 0.5;
	expl.additive = 0;
	expl.sprite_index = sExpl1Big;
	return expl;



}
