// Remove this Metroid if its saved encounter is already cleared.
//Insane
myid = 81;
if (global.metdead[myid] > 0) instance_destroy();
if (oControl.mod_monstersextreme =! 1) instance_destroy();
