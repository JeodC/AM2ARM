// State machine: "source" -> "dest" -> "confirm" -> back to "source";
// "restart" after unlocks were applied. Spawner sets has_slot[]/has_unlocks
// then fires event_user(0) to build the first screen.
state = "source";
// Draw_0 runs in room space (the port's Draw GUI layer is display-sized, so
// GUI-event text renders microscopic); -100 keeps the dialog above the cards.
depth = -100;
has_slot[0] = 0;
has_slot[1] = 0;
has_slot[2] = 0;
has_unlocks = 0;
applied_unlocks = 0;
pend_src = -1;
pend_dst = -1;
pend_kind = "";
pend_return = "source";
confirm_sel = 1;     // default No, like oSlotMenuOverwrite
cursel = 0;
item_count = 0;
lblstr = get_text("Title", "GameSlot_OverwriteConfirm");
yesstr = get_text("GlobalOptions", "Yes");
nostr = get_text("GlobalOptions", "No");
for (var i = 0; i < 5; i += 1) {
    item_kind[i] = "";
    item_val[i] = -1;
    item_card[i] = noone;
    item_row[i] = noone;
}

// Methods declared HERE, not in Step_0: event_user(0) fires before the
// first Step, and a function statement only exists once its event has run.
function sel_apply()
{
    if (item_kind[cursel] == "slot") {
        global.saveslot = item_val[cursel];
        global.curropt = -1;
        global.tiptext = get_text("Misc",
            (state == "source") ? "RestorePickSlot_Tip" : "RestorePickDest_Tip");
    } else {
        global.saveslot = -1;
        var r = item_row[cursel];
        if (instance_exists(r)) global.curropt = r.optionid;
        if (item_kind[cursel] == "unlocks") global.tiptext = get_text("Misc", "RestoreUnlocks_Tip");
        else if (item_kind[cursel] == "done") global.tiptext = get_text("Misc", "PickerDone_Tip");
        else global.tiptext = get_text("GlobalOptions", "Exit_Tip");
    }
}

function picker_exit()
{
    global.saveslot = 0;   // -1 (row selected) would break file-select nav
    if (applied_unlocks) {
        // Unlock files load at boot; restart to pick them up.
        state = "restart";
        global.tiptext = get_text("Misc", "RestoreDone");
        alarm[0] = 120;
    } else {
        instance_create(50, 92, oOptionsData);
        instance_destroy();
    }
}
