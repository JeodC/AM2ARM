// Remove this Metroid if its saved encounter is already cleared.
// Original Monster
myid = 47;
if (global.metdead[myid] > 0) instance_destroy();
