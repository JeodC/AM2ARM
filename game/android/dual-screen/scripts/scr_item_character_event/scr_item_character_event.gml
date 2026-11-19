function scr_item_character_event() {
	// Dispatch expansion collection by the current sprite, including randomized replacements.
	switch (sprite_index)
	{
	    case sItemMissile:
	    scr_missile_character_event();
	    break;
	    case sItemSuperMissile:
	    scr_supermissile_character_event();
	    break;
	    case sItemEnergyTank:
	    scr_energytank_character_event();
	    break;
	    case sItemPowerBomb:
	    scr_powerbomb_character_event();
	    break;    
	}



}
