
// Play the nearby trooper battle sound until the first Omega introduction has been triggered.
sound = sndGFTrooperBattleLoop;
radius = 300;
maxradius = 900;
minvol = 0;
maxvol = 1;
if (global.event[300] == 1) instance_destroy();
