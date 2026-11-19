function scr_variasuitswap() {
	// Keep an already equipped Gravity Suit; otherwise equip Varia when this pickup is applied.
	if ((global.item[9] == 1) && (global.currentsuit == 2)) { //syntax fixed for YYC?
	    //show_debug_message("TRYING TO SET GRAVITY");
	    global.currentsuit = 2;
	} else { 
	    //show_debug_message("TRYING TO SET VARIA");
	    global.currentsuit = 1; 
	}



}
