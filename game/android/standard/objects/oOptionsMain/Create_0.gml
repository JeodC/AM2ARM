global.curropt = 0;
lastitem = 4 + (os_type == os_android);
active = 0;
alarm[0] = 5;
event_user(0);
with (oSS_Fg) op_text1 = get_text("OptionsMain", "Title");
tip[0] = get_text("OptionsMain", "Display_Tip");
tip[1] = get_text("OptionsMain", "Sound_Tip");
tip[2] = get_text("OptionsMain", "Control_Tip");
tip[3] = get_text("ExtrasMenu", "Extras_Tip");
if (os_type == os_android) {
    tip[4] = get_text("Misc", "DataMenu_Tip");
    tip[5] = get_text("GlobalOptions", "Exit_Tip");
} else tip[4] = get_text("GlobalOptions", "Exit_Tip");
global.tiptext = tip[global.curropt];

