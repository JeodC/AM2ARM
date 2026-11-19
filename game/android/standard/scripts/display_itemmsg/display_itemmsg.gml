/// @description  display_itemmsg(text1, text2, btn1_name, btn2_name)
function display_itemmsg(argument0, argument1, argument2, argument3) {
	// Save the pickup text and camera position for the separate item-message room.
	global.itmtext1 = argument0;
	global.itmtext2 = argument1;
	global.btn1_name = argument2;
	global.btn2_name = argument3;
	global.ingame = 0;
	global.targetx = oCharacter.x;
	global.targety = oCharacter.y;
	global.offsetx = 0;
	global.offsety = 0;
	global.camstartx = oCamera.x;
	global.camstarty = oCamera.y;
	with (oCamera) {
	    targetx = x;
	    targety = y;
	}
	// Keep the gameplay room in memory with its player and camera while the message room is shown.
	room_persistent = true;
	oCharacter.persistent = false;
	oCamera.persistent = false;
	global.currentroom = room;
	global.transitiontype = 3;
	with (oControl) event_user(3);
	room_goto(itemroom);



}
