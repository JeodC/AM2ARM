///   am2r_string_split()
function am2r_string_split(argument0, argument1, argument2) {
	var num, newVal, sepNum, delemiter;
	num = argument1;
	newVal = "";
	sepNum = 0;
	delemiter = argument2;
	// Collect the requested zero-based segment of text separated by a single character.
	for (i = 1; i < string_length(argument0) + 1; i += 1) {
	    if (string_char_at(argument0, i) == delemiter) {
	        sepNum += 1;
	        i += 1;
	    }
	    if (sepNum == num) newVal += string_char_at(argument0, i);
	}
	return newVal;



}
