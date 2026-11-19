/// @description  draw_character(sprite, x, y, sprite2, s2ox, s2oy, sprite3, s3ox, s3oy, s3angle, facing, color, alpha, s3show)
function draw_character(argument0, argument1, argument2, argument3, argument4, argument5, argument6, argument7, argument8, argument9, argument10, argument11, argument12, argument13, argument14) {

	if (!oControl.msr_fusionsuit) {
	    if ((oControl.mod_fusion)) { // Fusion suit
	        if (global.currentsuit == 0) { // Power
	            pal_swap_set(sPalFusion0, 1, false);
	        } else if (global.currentsuit == 1) { // Varia
	            pal_swap_set(sPalFusion1, 1, false);
	        } else if (global.currentsuit == 2) { // Gravity
	            pal_swap_set(sPalFusion2, 1, false);
	        }
	    } else { // Custom color swaps
	        // Port parity: upstream gated these off on Android for the ancient 1.1-era
	        // port. The palettes only load if the user ships the files (PowerPalette
	        // stays -1 otherwise), so behave like PC and let modders have them.
	        if (global.currentsuit == 0 && oControl.PowerPalette != -1) { // Power
	            pal_swap_set(oControl.PowerPalette, 1, false);
	        } else if (global.currentsuit == 1 && oControl.VariaPalette != -1) { // Varia
	            pal_swap_set(oControl.VariaPalette, 1, false);
	        } else if (global.currentsuit == 2 && oControl.GravityPalette != -1) { // Gravity
	            pal_swap_set(oControl.GravityPalette, 1, false);
	        }
	    }
	}

	// Compose the body and extra arm sprites, then show the missile cannon when armed.
	draw_sprite_ext(argument0, argument14, argument1, argument2, argument10, 1, 0, argument11, argument12);
	draw_sprite_ext(argument3, argument14, argument1 + argument4, argument2 + argument5, argument10, 1, 0, argument11, argument12);
	if (argument13 == 1) {
	    draw_sprite_ext(argument6, argument14, argument1 + argument7, argument2 + argument8, argument10, 1, argument9, argument11, argument12);
	}

	// Finish the character palette effect before later drawing uses another shader.
	shader_reset();



}
