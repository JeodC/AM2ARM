/// @description  get_floor_material()
function get_floor_material() {
	// leaks `bl_id`
	// Try beneath the feet and their edges for a solid whose material selects the contact sound.
	bl_id = instance_position(x, y + 8, oSolid);
	if (bl_id < 0) bl_id = instance_position(x + 6, y + 2, oSolid);
	if (bl_id < 0) bl_id = instance_position(x - 6, y + 2, oSolid);
	if (bl_id > 0) {
	    return bl_id.material;
	} else return 0;



}
