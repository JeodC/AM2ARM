function scr_powerbomb_character_event() {
	// Use the inherited pickup event for collection; later Power Bomb Tanks also request a short notification.
	if (active) {
	    if (global.maxpbombs == 0) {
	        event_inherited();
	    } else {
	        itemtype = 1;
	        popup_text(get_text("Notifications", "PowerBombTank"));
	        event_inherited();
	    }
	    // Increase Power Bomb capacity by the difficulty-dependent amount and refill it.
	    if (global.difficulty < 2) global.maxpbombs += 2;
	    if (global.difficulty == 2) global.maxpbombs += 1;
	    global.pbombs = global.maxpbombs;
	    global.ptanks += 1;
	}



}
