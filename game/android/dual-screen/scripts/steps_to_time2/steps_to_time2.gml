/// @description  steps_to_time2(steps)
function steps_to_time2(argument0) {
	// Converts a number of steps into "hh:mm:ss" format.
	// Interpret the counter at sixty steps per second before formatting its time fields.
	sec = floor(argument0 / 60);
	minute = floor(sec / 60);
	hour = floor(minute / 60);
	sec2 = sec - minute * 60;
	minute2 = minute - hour * 60;
	if (minute2 < 10) {
	    minstr = "0" + string(minute2);
	} else minstr = string(minute2);
	if (sec2 < 10) {
	    secstr = "0" + string(sec2);
	} else secstr = string(sec2);
	if (hour < 10) {
	    hourstr = "0" + string(hour);
	} else hourstr = string(hour);
	return hourstr + ":" + minstr + ":" + secstr;



}
