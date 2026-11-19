// GM2026 fix: was the GMS1.4 numeric id 375, which only still resolved to rm_a8h01
// by coincidence of room ordering; use the symbolic name so reordering can't break it.
target_room = rm_a8h01;
target_x = 2400;
target_y = 1152;
elev_dir = 1;
bottom = 1;
if (global.event[176] == 0) instance_destroy();