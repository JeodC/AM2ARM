if (active) {
    // Menu DOWN
    if (oControl.kDown > 0 && (oControl.kDownPushedSteps == 0 || oControl.kDownPushedSteps > 30 && timer == 0)) {      
        global.curropt += 1;
        // Wrap
        if (global.curropt > menuSize) global.curropt = 0;
        // Skip inactive
        while (canEdit[global.curropt] == 0) {
            global.curropt += 1;
            // Wrap again (safety)
            if (global.curropt > menuSize) global.curropt = 0;
        }
        // New target
        targetY = op[global.curropt].y + 16;
        if (targetY > vTargetY) targetY = vTargetY;
        sfx_play(sndMenuMove);
        global.tiptext = tip[global.curropt];
    } // Menu UP
    else if (oControl.kUp > 0 && (oControl.kUpPushedSteps == 0 || oControl.kUpPushedSteps > 30 && timer == 0)) {
        global.curropt -= 1;
        // Wrap
        if (global.curropt < 0) global.curropt = menuSize;
        // Skip inactive
        while (canEdit[global.curropt] == 0)
        {
            global.curropt -= 1;
            // Wrap again (safety)
            if (global.curropt < 0) global.curropt = menuSize;
        }
        // New target
        targetY = op[global.curropt].y + 16;
        if (targetY > vTargetY) targetY = vTargetY;
        sfx_play(sndMenuMove);
        global.tiptext = tip[global.curropt];
    }
    
    var input = oControl.kRight - oControl.kLeft;
    var inputSteps = oControl.kRightPushedSteps - oControl.kLeftPushedSteps;
    
    // Menu LEFT and RIGHT
    if (input != 0 && inputSteps == 0 && global.curropt < menuSize && oControl.kDown == 0 && oControl.kUp == 0) {
        
        if (os_type != os_android) {
            // Fullscreen
            if (global.curropt == opFullscreen) {
                global.opfullscreen = !global.opfullscreen;
                set_fullscreen(global.opfullscreen);
                if (!global.opfullscreen) {
                    global.opscale = 1;
                    // Update window scale
                    alarm[1] = 1;
                }
            }
            
            // Scale
            if (global.curropt == opScale) {
                if (global.opfullscreen) {
                    global.opscale = wrap(global.opscale + input, 0, 4);
                }
                if (!global.opfullscreen) {
                    global.opscale = wrap(global.opscale + input, 1, 4)
                    set_window_scale(global.opscale);
                }
            }
        }
        
        // VSync
        if (global.curropt == opVSync) {
            global.opvsync = !global.opvsync;
            display_reset(0, global.opvsync);
            if (!global.opfullscreen) set_window_scale(global.opscale);
        }
        

        // Sensitivity Mode
        if (global.curropt == opSensitivity) {
            global.sensitivitymode = !global.sensitivitymode;
        }
        
        if (global.curropt == opNano) global.nano_enabled = !global.nano_enabled;

        // Widescreen
        if (global.curropt == opWidescreen && !oControl.thor_aspect_locked) {
            global.widescreen_enabled = !global.widescreen_enabled;
            if (room == rm_options) {
                oControl.widescreen = global.widescreen_enabled;
                if (global.widescreen_enabled == 0) {
                    __view_set( e__VW.Visible, 1, false );
                }
                
                if (global.opfullscreen == 0) {
                    set_window_scale(window_get_height()/240);
                    window_set_position(window_get_x()+((53-(global.widescreen_enabled*106))*(window_get_height()/240)),window_get_y());
                }
                if (global.opfullscreen == 1 || os_type == os_android) {
                    display_reset(0, global.opvsync);
                }
            }
        }

        // Apply hardware changes in oControl context, then save the selected profile independently of the menu instance.
        if (global.curropt == opDeviceProfile) {
            with (oControl) {
                thor_profile_apply(wrap(thor_profile + input, 0, array_length(thor_profiles) - 1));
                global.widescreen_enabled = !thor_aspect_locked;
                if (room != rm_subscreen) widescreen = global.widescreen_enabled;
                ini_open("config.ini");
                ini_write_real("DualScreen", "DeviceProfile", thor_profile);
                ini_close();
            }
        }

        if (global.curropt == opSwapScreens && canEdit[opSwapScreens]) {
            with (oControl) thor_swap_set(!thor_swap_screens);
        }

        // Move health and ammunition between the two screens.
        if (global.curropt == opShowHUD) {
            with (oControl) {
                thor_hud_top = !thor_hud_top;
                thor_apply_hud_layout();
            }
        }
        // Show Map
        if (global.curropt == opShowMap) global.ophudshowmap = !global.ophudshowmap;
        
        // Monster Counter
        if (global.curropt == opCounterStyle) {
            global.ophudshowmetrcount = wrap(global.ophudshowmetrcount + input, 0, 2);
        }
        
        // Show Hints
        if (global.curropt == opShowHints) global.ophudshowhints = !global.ophudshowhints;
        
        // Button Prompt Style
        if (buttonsEnabled && global.curropt == opButtonType) {
            var inputMax = 5 - ((os_type == os_android) * 2);
            oControl.mod_buttonsconfig = wrap(oControl.mod_buttonsconfig + input, 0, inputMax);
            
            // Update events
            event_user(3);
            event_user(4);
        }
        
        // Show Scans
        if (global.curropt == opShowScans) global.ophudshowlogmsg = !global.ophudshowlogmsg;
        
        // Language
        if (global.curropt == opLanguage) {
            global.currentlanguage = wrap(global.currentlanguage + input, 0, langCount - 1);
            port_locale_refresh();
            
            // Update events
            event_user(3);
            event_user(4);
            global.tiptext = tip[global.curropt];
        }
        
        sfx_play(sndMenuMove);
        
        // Update text
        event_user(2);
    }

    if (oControl.kMenu1 && oControl.kMenu1PushedSteps == 0) {
        // On Exit, reload resources, save options, reset the menu camera, and recreate the main settings menu.
        if (global.curropt == menuSize) {
            load_resources();
            save_gameoptions();
            __view_set( e__VW.Object, 0, noone );
            __view_set( e__VW.YView, 0, 0 );
            instance_create(50, 92, oOptionsMain);
            instance_destroy();
            sfx_play(sndMenuSel);
        }
    }
}

// Ease the menu camera toward the selected row while the timer limits held-key repeats.
if (targetY != y) y += (targetY - y) / 10;

timer -= 1;

if (timer < 0) timer = 8;
