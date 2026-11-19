function scr_SubScrTop_swap() {

	// Choose inventory-panel art with spaces for the ammo types whose tanks have been collected.
	if (global.stanks > 0 && global.ptanks > 0) return bg_SubScrTop;
	else if (global.stanks > 0) return bg_SubScrTop_SM;
	else if (global.ptanks > 0) return bg_SubScrTop_PB;
	else return bg_SubScrTop_M;




}
