/// @description  init_bg(bg_id)
function init_bg(argument0) {
	// Initialize the calling background object's layers before a preset fills their art and parallax values.
	bgno = argument0;
	for (i = 0; i < bgno; i += 1) {
	    bgid[i] = bgScreenGuide;
	    xoff[i] = 0;
	    yoff[i] = 0;
	    xratio[i] = 1;
	    yratio[i] = 1;
	    xscale[i] = 1;
	    yscale[i] = 1;
	    alpha[i] = 1;
	    tile[i] = 1;
	}



}
