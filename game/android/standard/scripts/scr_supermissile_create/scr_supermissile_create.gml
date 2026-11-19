function scr_supermissile_create() {
	// Load the Super Missile message and select the help button for the current missile-control style.
	text1 = get_text("Items", "SuperMissileTank");
	text2 = get_text("Items", "SuperMissileTank_Text");
	if (global.opmslstyle == 1) { btn1_name = "Missile"; }
	if (global.opmslstyle == 0) { btn1_name = "Select"; }



}
