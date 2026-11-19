image_speed = 0;
open = 0;
// Create the physical barrier separately from the animated door sprite.
block = instance_create(x - 8, y, oSolid1);
block.image_yscale = 4;
block.isDoorBlock = 1; // GM2026 fix: see oBeam Collision_oSolid
alarm[0] = 1;
lock = 0;
lockdelay = 0;
showlock = 1;
lockspr = sDoor1Locks;
event = -1;
highlight = 0;
hltimer = 0;
hlalpha = 0;
stayopen = 0;
alarm[2] = 10;

