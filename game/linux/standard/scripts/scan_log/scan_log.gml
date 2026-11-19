/// @description  scan_log(log_id, text, delay, mode)
function scan_log(argument0, argument1, argument2, argument3) {
	// Start the timed scan for a new entry or an update when the matching log state allows it.
	if (global.log[argument0] == 0 && argument3 == 0 || global.log[argument0] == 1 && argument3 == 1 && !instance_exists(oScanning)) {
	    scan = instance_create(0, 0, oScanning);
	    scan.lognumber = argument0;
	    scan.text = argument1;
	    scan.alarm[0] = argument2;
	    scan.mode = argument3;
    
    
    
	}



}
