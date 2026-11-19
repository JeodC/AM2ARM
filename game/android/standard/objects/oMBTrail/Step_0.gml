if (oCharacter.state == 23 || oCharacter.state == 24) {
    // Keep recent Morph Ball positions so Draw can leave a fading trail behind Samus.
    for (var _trail_index = 10; _trail_index > 0; --_trail_index) {
        sx[_trail_index] = sx[_trail_index - 1];
    }
    sx[0] = x;
    for (var _trail_index = 10; _trail_index > 0; --_trail_index) {
        sy[_trail_index] = sy[_trail_index - 1];
    }
    sy[0] = y;
    x = oCharacter.x;
    y = oCharacter.y;
    
    switch (oControl.mod_fusion) {
        case 1: {
            ///make_color_rgb(red, green, blue);            
            if (oControl.msr_fusionsuit == 1)
            {
                if (global.currentsuit == 0) image_blend = make_color_rgb(oControl.Trail_P_R_F_SR, oControl.Trail_P_G_F_SR, oControl.Trail_P_B_F_SR);
            } 
            else
            {
                if (global.currentsuit == 0) image_blend = make_color_rgb(oControl.Trail_P_R_F, oControl.Trail_P_G_F, oControl.Trail_P_B_F);
            }
            
            if (oControl.msr_fusionsuit == 1)
            {
                if (global.currentsuit == 1) image_blend = make_color_rgb(oControl.Trail_V_R_F_SR, oControl.Trail_V_G_F_SR, oControl.Trail_V_B_F_SR);
            } 
            else
            {
                if (global.currentsuit == 1) image_blend = make_color_rgb(oControl.Trail_V_R_F, oControl.Trail_V_G_F, oControl.Trail_V_B_F);
            }
            
            if (oControl.msr_fusionsuit == 1)
            {
                if (global.currentsuit == 2) image_blend = make_color_rgb(oControl.Trail_G_R_F_SR, oControl.Trail_G_G_F_SR, oControl.Trail_G_B_F_SR); 
            }
            else
            {
                if (global.currentsuit == 2) image_blend = make_color_rgb(oControl.Trail_G_R_F, oControl.Trail_G_G_F, oControl.Trail_G_B_F); 
            }
            
            break;
            }
        default: {
            if (global.currentsuit == 0) image_blend = make_color_rgb(oControl.Trail_P_R, oControl.Trail_P_G, oControl.Trail_P_B); //c_yellow;
            if (global.currentsuit == 1) image_blend = make_color_rgb(oControl.Trail_V_R, oControl.Trail_V_G, oControl.Trail_V_B); //c_lime;
            if (global.currentsuit == 2) image_blend = make_color_rgb(oControl.Trail_G_R, oControl.Trail_G_G, oControl.Trail_G_B); //c_aqua;
            break;
            }
    }
    
} else instance_destroy(); // if (oCharacter.state == 23 || oCharacter.state == 24) else

