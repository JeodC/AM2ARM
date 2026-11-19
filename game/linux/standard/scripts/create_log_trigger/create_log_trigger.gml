/// @description create_log_arrow(isTrooperLog?, lognum, x, y, yoffset, visible);
/// @param isTrooperLog?
/// @param  lognum
/// @param  x
/// @param  y
/// @param  yoffset
/// @param  visible
function create_log_trigger() {

	// NEWLOGSCODE

	var inst;

	// Create a normal log trigger only while its entry is undiscovered.
	if(argument[0] == false) {
	    if(global.log[argument[1]] == 0) {
	        inst = instance_create(argument[2], argument[3], oLogTrigger);
	        with(inst) {
	            yoffset = argument[4];
	            lognum = argument[1];
	            event_user(0);
	            visible = argument[5];
	        }
	    }
	}
	else {
	    // Trooper records share a log entry, so check their individual collected IDs instead.
	    var arrayHasValue = false;
	    for (var i = 0, iLen = array_length_1d(global.trooperlog); i < iLen; i++) {
	       if (global.trooperlog[i] == argument[1]) {
	           arrayHasValue = true;
	           break;
	       }
	    }
    
	    if(!arrayHasValue) {
	        inst = instance_create(argument[2], argument[3], oLogTrigger);
	        with(inst) {
	            yoffset = argument[4];
	            trooperlognum = argument[1];
	            event_user(0);
	            visible = argument[5];
	        }
	    }
	}



}
