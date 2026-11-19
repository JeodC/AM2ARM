/// Build source or destination screen: slot cards + option rows.
// Tear down whatever the previous screen created.
for (var i = 0; i < 5; i += 1) {
    if (instance_exists(item_card[i])) with (item_card[i]) instance_destroy();
    if (instance_exists(item_row[i])) with (item_row[i]) instance_destroy();
    item_kind[i] = "";
    item_val[i] = -1;
    item_card[i] = noone;
    item_row[i] = noone;
}
item_count = 0;
var rowy = 176;

if (state == "source") {
    for (var n = 0; n < 3; n += 1) {
        if (!has_slot[n]) continue;
        if (sv6_load_details("restorestage_save" + string(n + 1)) != 1) {
            // Corrupt: the loader already deleted the staged copy and told
            // the player. Drop the entry.
            has_slot[n] = 0;
            continue;
        }
        var c = instance_create(64, 40 + 44 * n, oMenuSaveSlot);
        c.slot = n;
        c.saveexists = 1;
        c.smonsters = global.monstersleft;
        c.timestring = steps_to_time2(global.gametime);
        c.saveroom = global.save_room;
        c.setanks = global.etanks;
        c.sprogress = string(round(global.itemstaken / 88 * 100));
        c.sdifficulty = global.difficulty;
        if (oControl.mod_fusion == 1) c.sdifficulty = 3;
        if (oControl.seed != "") c.sseed = " [" + string(oControl.seed) + "]";
        else c.sseed = "";
        c.smode = global.gamemode;
        with (c) event_user(0);
        item_kind[item_count] = "slot";
        item_val[item_count] = n;
        item_card[item_count] = c;
        item_count += 1;
    }
    scr_default_global_items();
    if (has_unlocks) {
        var r = instance_create(64, rowy, oPauseOption);
        r.optionid = 100 + item_count;
        r.label = get_text("Misc", "RestoreUnlocks");
        item_kind[item_count] = "unlocks";
        item_row[item_count] = r;
        item_count += 1;
        rowy += 16;
    }
    var d = instance_create(64, rowy, oPauseOption);
    d.optionid = 100 + item_count;
    d.label = get_text("Misc", "PickerDone");
    item_kind[item_count] = "done";
    item_row[item_count] = d;
    item_count += 1;
} else {
    // Destination: always the three live slots (empty ones render New Game
    // style and are valid targets), plus Back.
    for (var n = 0; n < 3; n += 1) {
        var c = instance_create(64, 40 + 44 * n, oMenuSaveSlot);
        c.slot = n;
        var fname = "save" + string(n + 1);
        // Preview a checked copy: the legacy loader can delete bad input.
        var preview = "restorepreview_" + fname;
        file_delete(preview);
        if (file_exists(fname)) file_copy(fname, preview);
        if (scr_stage_normalize(preview) == 1 && sv6_load_details(preview) == 1) {
            c.saveexists = 1;
            c.smonsters = global.monstersleft;
            c.timestring = steps_to_time2(global.gametime);
            c.saveroom = global.save_room;
            c.setanks = global.etanks;
            c.sprogress = string(round(global.itemstaken / 88 * 100));
            c.sdifficulty = global.difficulty;
            if (oControl.mod_fusion == 1) c.sdifficulty = 3;
            if (oControl.seed != "") c.sseed = " [" + string(oControl.seed) + "]";
            else c.sseed = "";
            c.smode = global.gamemode;
        } else c.saveexists = 0;
        file_delete(preview);
        with (c) event_user(0);
        item_kind[item_count] = "slot";
        item_val[item_count] = n;
        item_card[item_count] = c;
        item_count += 1;
    }
    scr_default_global_items();
    var b = instance_create(64, rowy, oPauseOption);
    b.optionid = 100 + item_count;
    b.label = get_text("Misc", "PickerBack");
    item_kind[item_count] = "back";
    item_row[item_count] = b;
    item_count += 1;
}
cursel = 0;
sel_apply();
