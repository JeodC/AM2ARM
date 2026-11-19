/// @description  make_notification(text1, text2, delay, btn1, btn2)
function make_notification(argument0, argument1, argument2, argument3, argument4) {
	// Replace the current notification and attach its text, button hints and display duration.
	with (oNotification) instance_destroy();
	notif = instance_create(0, 0, oNotification);
	notif.text1 = argument0;
	notif.text2 = argument1;
	notif.alarm[0] = argument2;
	notif.btn1_name = argument3;
	notif.btn2_name = argument4;



}
