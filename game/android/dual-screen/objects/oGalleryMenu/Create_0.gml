// The full picture fades over both the preview cards and the Exit label.
// Equal-depth room instances draw in creation order after project conversion.
depth = -1;
global.curropt = 0;
repeat (3) {
    if (global.gallery[global.curropt] == 0) global.curropt += 1;
}
lastitem = 2;
state = 1;
active = 0;
alarm[0] = 5;
img_alpha = 0;
img_fadeout = 0;
bg_id = -4;
op3 = instance_create(16, 216, oPauseOption);
op3.optionid = 3;
op3.label = get_text("GlobalOptions", "Exit");

