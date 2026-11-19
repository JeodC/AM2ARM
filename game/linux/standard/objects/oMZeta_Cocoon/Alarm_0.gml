// Restore an opened cocoon on later visits; an already seen hatching can spawn Zeta without replaying it.
if (global.metdead[myid] > 0) {
    //instance_destroy();
    //idle = 1;
    state = 3;
    exit;
}
if (global.event[205] > 0) event_user(1);

