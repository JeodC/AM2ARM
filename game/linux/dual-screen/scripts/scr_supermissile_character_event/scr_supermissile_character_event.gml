function scr_supermissile_character_event() {
	// Use the inherited pickup event for collection; later Super Missile Tanks also request a short notification.
	if (active) {
	    if (global.maxsmissiles == 0) {
	        event_inherited();
	    } else {
	        itemtype = 1;
	        popup_text(get_text("Notifications", "SuperMissileTank"));
	        event_inherited();
	    }
	    // Increase Super Missile capacity by the difficulty-dependent amount and refill it.
	    if (global.difficulty < 2) global.maxsmissiles += 2;
	    if (global.difficulty == 2) global.maxsmissiles += 1;
	    global.smissiles = global.maxsmissiles;
	    global.stanks += 1;
	}



}
