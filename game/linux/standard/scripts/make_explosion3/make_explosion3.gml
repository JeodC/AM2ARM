/// @description  make_explosion3(x, y)
function make_explosion3(argument0, argument1) {
	// Create the second explosion animation at its foreground depth.
	expl = instance_create(argument0, argument1, oFXAnimSpark);
	expl.image_speed = 0.5;
	expl.additive = 0;
	expl.sprite_index = sExpl2;
	expl.depth = -5;



}
