/// @description  popup_text(text)
function popup_text(argument0) {
	// Replace the previous short popup so only the latest message is displayed.
	with (oPopupText) instance_destroy();
	var t = instance_create(0, 0, oPopupText);
	t.text = argument0;



}
