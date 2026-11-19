/// @description  steps_to_time(steps)
function steps_to_time(argument0) {
	// Converts a number of steps into "mm:ss.f" format
	// Interpret the counter at sixty steps per second before formatting its time fields.
	sec = floor(argument0 / 60);
	dec = floor((argument0 / 60 - sec) * 100);
	minute = floor(sec / 60);
	sec2 = sec - minute * 60;
	if (minute < 10) {
	    minstr = "0" + string(minute);
	} else minstr = string(minute);
	if (sec2 < 10) {
	    secstr = "0" + string(sec2);
	} else secstr = string(sec2);
	if (dec < 10) {
	    decstr = "0" + string(dec);
	} else decstr = string(dec);
	return minstr + ":" + secstr + "." + decstr;



}
