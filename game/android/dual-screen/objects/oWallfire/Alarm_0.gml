// Open the turret first; Alarm 1 releases the shot after a difficulty-dependent warning.
state = 2;
if (global.difficulty == 0) alarm[1] = 30;
if (global.difficulty == 1) alarm[1] = 20;
if (global.difficulty == 2) alarm[1] = 10;

