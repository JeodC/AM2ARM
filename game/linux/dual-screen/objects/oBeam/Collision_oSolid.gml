// GM2026 fix: the door's invisible block (oSolid1) overlaps the door's own hitbox, and
// GM2026's collision-pair ordering sometimes processes (beam,block) before (door,beam) —
// the beam died on the block without the door ever seeing it (intermittent "blue door
// won't open on first shot", rm_a1a03 leftmost door). Beams ignore tagged door blocks;
// oDoor's own Collision_oBeam opens the door or eats the beam, exactly as designed.
if (variable_instance_exists(other, "isDoorBlock")) exit;

if (wbeam == 0) {
    event_user(0);
    instance_destroy();
}
with (other) if (sprite_index == sBlockBomb) {
    event_user(1);
    visible = true;
}

