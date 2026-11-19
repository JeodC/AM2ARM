
// Fade the covering terrain for the current time of day when Samus enters this region.
areax = 320+64;
areay = 32;
if (global.timeofday == 0) fade_depth = -101;
if (global.timeofday == 1) fade_depth = -111;
if (global.timeofday == 2) fade_depth = -121;
