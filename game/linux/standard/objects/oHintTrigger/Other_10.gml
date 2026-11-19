// Count time spent touching the hint region, then show its message once and remember it.
steps += 1;
if (global.hint[myid] == 1) {
    instance_destroy();
} else if (steps >= targetsteps) {
    make_notification(text1, text2, duration, btn1_name, btn2_name);
    global.hint[myid] = 1;
    instance_destroy();
}

