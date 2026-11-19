/// @description  anim_frame(sprite)
function anim_frame(argument0, argument1, argument2) {
	var numspr, frame;
	// Advance a manually controlled animation frame and stop at either end of the sprite.
	numspr = sprite_get_number(argument0);
	frame = argument1;
	frame += argument2;
	if (frame > numspr - 1) {
	    frame = numspr - 1;
	} else if (frame < 0) frame = 0;
	return frame;



}
