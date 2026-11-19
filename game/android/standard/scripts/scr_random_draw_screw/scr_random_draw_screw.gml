function scr_random_draw_screw() {

	// Reshuffle until a remaining item other than Screw Attack is selected.
	while (true)
	{
	    checkcounter = 0;
	    var shuff = ds_list_find_value(oControl.list_locations, ds_list_size(oControl.list_locations) - 1);
	    if (shuff == 8) { } else { checkcounter++; }
	    if (checkcounter == 1) { break; }
	    ds_list_shuffle(oControl.list_locations);
	}
	ds_list_delete(oControl.list_locations, ds_list_size(oControl.list_locations) - 1);
	return shuff;



}
