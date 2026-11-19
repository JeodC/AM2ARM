bubble = instance_create(x, y + random_range(-16, 16), oLBubble);
if (instance_exists(bubble)) {
    bubble.hspeed = random_range(2, 7);
    bubble.vspeed = 0;
    bubble.alarm[0] = 180 + random(300);
    bubble.depth = 85;
    // Preserve the original random draws and alarm cadence. Nano keeps one
    // third of this decorative stream; fish and their attacks are unchanged.
    if (global.nano_enabled) {
        nano_bubble_phase = (nano_bubble_phase + 1) mod 3;
        if (nano_bubble_phase != 0) instance_destroy(bubble);
    }
}
alarm[0] = 2;

