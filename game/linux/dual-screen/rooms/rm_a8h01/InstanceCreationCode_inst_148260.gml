
// GM2026 fix: 170 was GMS1.4's numeric id for rm_a0h13; room ids were reassigned
// in the port, so the ride-down arrival check (room == elevator_target_room) never
// passed and Samus stayed in the GFELEVATOR state forever — the bottom-of-elevator softlock.
target_room = rm_a0h13;
target_x = 160;
target_y = 192;
elev_dir = 0;
