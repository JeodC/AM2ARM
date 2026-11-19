// Resolve the ending art by name; legacy background numbers are different sprite IDs after conversion.
if (global.curropt == 0) bg_id = bgEnding1;
if (global.curropt == 1) bg_id = bgEnding2;
if (global.curropt == 2) bg_id = bgEnding3;
state = 2;
img_alpha = 0;
img_fadeout = 0;

