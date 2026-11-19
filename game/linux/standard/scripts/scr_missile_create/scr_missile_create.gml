function scr_missile_create() {
	// Choose the translated Missile Tank message for the current difficulty.
	text1 = get_text("Items", "MissileTank");
	text2 = get_text("Items", "MissileTank_Text");
	if (global.difficulty == 2) text2 = get_text("Items", "MissileTank_TextHard");




}
