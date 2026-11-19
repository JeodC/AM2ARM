/// @description  anim_frame_cycle(sprite)
function anim_frame_cycle(argument0, argument1, argument2) {
	var numspr, frame;
	// Advance a manually controlled animation frame, restarting at the opposite end when it passes an edge.
	numspr = sprite_get_number(argument0);
	frame = argument1;
	frame += argument2;
	if (frame > numspr - 1) {
	    frame = 0;
	} else if (frame < 0) frame = numspr - 1;
	return frame;



}
