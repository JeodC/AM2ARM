function scr_powerbomb_create() {
	// Load the Power Bomb message and select the help button for the current missile-control style.
	text1 = get_text("Items", "PowerBombTank");
	text2 = get_text("Items", "PowerBombTank_Text");
	if (global.opmslstyle == 1) { btn1_name = "Missile"; }
	if (global.opmslstyle == 0) { btn1_name = "Select"; }



}
