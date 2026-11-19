if (instance_exists(oSlotMenu_Fusion)) op[3].hide = 1; // stop from selecting ID 3 when Fusion Difficulty is being selected
else op[3].hide = 0;

// Saves changed while this room was frozen persistent (restore picker in
// rm_options) -- re-read the slot files now that we're live again.
if (global.saves_dirty) {
    global.saves_dirty = 0;
    event_user(2);
}


if (active && sync_entry_pending) {
    sync_entry_pending = false;
    save_sync_request(true, false);
}
if (active && save_sync_busy()) {
    if (oControl.kMenu2 && oControl.kMenu2PushedSteps == 0) save_sync_cancel();
    exit;
}

if (active) {
    if (oControl.kDown && oControl.kDownPushedSteps == 0) {
        global.curropt += 1;
        if (global.curropt > lastitem) global.curropt = 0;
        global.saveslot = global.curropt;
        sfx_play(sndMenuMove);
    }
    if (oControl.kUp && oControl.kUpPushedSteps == 0) {
        global.curropt -= 1;
        if (global.curropt < 0) global.curropt = lastitem;
        global.saveslot = global.curropt;
        sfx_play(sndMenuMove);
    }
    if (oControl.kMenu1 && oControl.kMenu1PushedSteps == 0) {
        sfx_play(sndMenuSel);
        // An empty slot enters game setup; an existing slot offers continue, copy, or erase.
        if (global.curropt >= 0 && global.curropt < 3) {
            // Refresh a folder that may have received progress while this menu was idle.
            if (global.am2r_sync.enabled && current_time - global.am2r_sync.checked > 60000) {
                if (save_sync_request(true, false)) exit;
            }
            if (op[global.curropt].saveexists == 0) {
 
                if (global.mod_gamebeaten == 1)  { instance_create(0, 0, oSlotMenu_gametypes); }
                else { instance_create(0, 0, oSlotMenu_normal_only); }
                active = 0;
            } else {
                instance_create(0, 0, oSlotMenu1);
                active = 0;
            }
        }
        
        if (global.curropt == 4) {
            room_persistent = true;
            room_change(rm_options, 0);
        }
        
        if (global.curropt == 5 && op[5].enabled) {
            room_persistent = true;
            room_change(rm_gallery, 0);
        }
        if (global.curropt == 6) {
            room_persistent = true;
            global.creditsmenuopt = 1;
            room_change(rm_credits, 0);
        }
        if (global.curropt == 3 && op[3].enabled) {
            room_persistent = true;
            room_change(rm_gameplay, 0);
        }
        if (global.curropt == 7) game_end();
    } // if (oControl.kMenu1 && oControl.kMenu1PushedSteps == 0)
} // if (active)
if (image_alpha < 1 && fadein) image_alpha += 0.05;

