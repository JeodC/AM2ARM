// Keep the boss's warning color and power state, without decorative pulsing.
if (global.nano_enabled) {
    image_alpha = 0.35;
    image_index = color;
    visible = global.event[200] != 0 && nano_tile_slot == 0;
    exit;
}
i += 0.02;
if (i > 99999999) i = 0;
j = 0.05 + abs(sin(i));
if (j > 1) j = 1;
image_alpha = j;
if (global.event[200] == 0) {
    visible = false;
} else visible = true;
image_index = color;

