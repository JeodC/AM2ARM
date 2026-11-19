// Restore the barrier immediately and let Step animate the door closed before showing its lock.
if (open == 1) {
    block = instance_create(x - 8, y, oSolid1);
    block.image_yscale = 4;
block.isDoorBlock = 1; // GM2026 fix: see oBeam Collision_oSolid
    sfx_play_single(sndDoorClose);
    open = 0;
    lockdelay = 2;
    showlock = 0;
}

