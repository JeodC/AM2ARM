// Remove this Metroid if its saved encounter is already cleared.
//Insane
myid = 87;
if (global.metdead[myid] > 0) instance_destroy();
if (oControl.mod_monstersextreme =! 1) instance_destroy();