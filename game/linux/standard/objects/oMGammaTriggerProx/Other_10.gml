create_gamma(x, y, myid, facing);
// Wake the other dormant Gammas in this room just after this one starts.
with (oMGammaTriggerProx) alarm[0] = 1;
instance_destroy();

