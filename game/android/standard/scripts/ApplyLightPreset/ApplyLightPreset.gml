/// @description  ApplyLightPreset()
function ApplyLightPreset() {
	// Create one darkness overlay and player flashlight for the selected room-lighting preset.
	if (!instance_exists(oLightEngine)) {
	    if (global.darkness == 1) {
	        le = instance_create(0, 0, oLightEngine);
	        le.image_alpha = 0.5;
	        instance_create(oCharacter.x, oCharacter.y - 16, oFlashlight64);
	    }
	    if (global.darkness == 2) {
	        le = instance_create(0, 0, oLightEngine);
	        le.image_alpha = 0.8;
	        instance_create(oCharacter.x, oCharacter.y - 16, oFlashlight64);
	    }
	    if (global.darkness == 3) {
	        le = instance_create(0, 0, oLightEngine);
	        le.image_alpha = 0.9;
	        instance_create(oCharacter.x, oCharacter.y - 16, oFlashlight64);
	    }
	    if (global.darkness == 4) {
	        le = instance_create(0, 0, oLightEngine);
	        le.image_alpha = 1;
	        instance_create(oCharacter.x, oCharacter.y - 16, oFlashlight64);
	    }
	}



}

// Nano omits minor glows, so the fully dark preset needs the next lighter
// ambient level. Apply at draw time so toggling Nano and fading still work.
function light_mask_opacity(_alpha) {
    return global.nano_enabled && global.darkness == 4 ? _alpha * 0.9 : _alpha;
}
