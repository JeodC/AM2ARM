function scr_missile_character_event() {
	// Use the inherited pickup event for collection; later Missile Tanks also request a short notification.
	if (active) {
	    if (global.maxmissiles == oControl.mod_Mstartingcount) {
	        event_inherited();
	    } else {
	        itemtype = 1;
	        popup_text(get_text("Notifications", "MissileTank"));
	        event_inherited();
	    }
	    // Increase missile capacity by the difficulty-dependent amount and refill it.
	    if (global.difficulty < 2) global.maxmissiles += 5;
	    if (global.difficulty == 2) global.maxmissiles += 2;
	    global.missiles = global.maxmissiles;
	    global.mtanks += 1;
	}



}
