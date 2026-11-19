function scr_random_draw_gravity_spider() {

	// Exclude Gravity Suit and Spider Ball here, also checking their barrier dependence on Speed Booster.
	while (true)
	{
	    checkcounter = 0;
	    var shuff = ds_list_find_value(oControl.list_locations, ds_list_size(oControl.list_locations) - 1);    
	    if (shuff == 7 && (oControl.gravity_wall == true || oControl.spider_wall == true)) { } else { checkcounter++; }
	    if (shuff != 9) { checkcounter++; }
	    if (shuff != 2) { checkcounter++; }
	    if (checkcounter == 3) { break; }
	    ds_list_shuffle(oControl.list_locations);
	}
	ds_list_delete(oControl.list_locations, ds_list_size(oControl.list_locations) - 1);
	return shuff;



}
