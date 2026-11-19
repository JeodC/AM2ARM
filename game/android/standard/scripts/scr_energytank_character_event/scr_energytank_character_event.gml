function scr_energytank_character_event() {
	// Use the inherited pickup event for collection; later tanks also request a short notification.
	if (active) {
	    if (global.maxhealth < 100) {
	        event_inherited();
	    } else {
	        itemtype = 1;
	        popup_text(get_text("Notifications", "EnergyTank"));
	        event_inherited();
	    }
	    // Apply the configured tank size, refill health and record one more Energy Tank.
	    global.maxhealth += (100 * oControl.mod_etankhealthmult);
	    global.playerhealth = global.maxhealth;
	    global.etanks += 1;
	}



}
