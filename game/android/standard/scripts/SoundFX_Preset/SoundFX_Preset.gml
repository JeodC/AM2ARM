/// @description  SoundFX_Preset(ambient_id)
function SoundFX_Preset(argument0) {
	// Remember the room ambience selection and pass it to the retained sound-group helpers.
	if (global.soundamb != argument0) {
	    global.soundamb = argument0;
	    SetAmb_Player();
	    SetAmb_Weapons();
	    SetAmb_Enemies();
	}



}
