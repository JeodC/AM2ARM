
// Keep this patrol absent until the cave recedes, then use its room-specific turning interval.
if (global.lavastate <= 1) instance_destroy();
facing = 1;
timer = 220;
