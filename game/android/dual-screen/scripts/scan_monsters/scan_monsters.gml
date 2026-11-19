/// @description  scan_monsters(amount, event_id)
function scan_monsters(argument0, argument1) {
	// Start one Metroid-count scan carrying the amount and progression event to record.
	if (!instance_exists(oScanMonster)) {
	    scan = instance_create(0, 0, oScanMonster);
	    scan.ammount = argument0;
	    scan.eventno = argument1;
	}



}
