/// @description  check_linkid()
function check_linkid() {
	// Trigger shootable blocks sharing this nonzero link ID; each block handles its own user event.
	global.link_id = link_id;
	if (link_id != 0) with (oBlockShoot) if (link_id == global.link_id) event_user(0);



}
