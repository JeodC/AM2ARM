// GM2026 fix: GMS1.4 drew same-depth instances in creation order, which put this text ABOVE
// oGameOverBG's nebula image. GM2026 does not preserve that order — the background drew over the
// title (everything right of the bg's left edge at room x=98 was hidden; the "red line" was the
// sliver peeking past that edge). Explicit depth restores the reference layering. Same divergence
// class as the collision-order fixes (see oBeam Collision_oSolid).
depth = -50;
gameover_str = get_text("GameOver", "GameOverTitle"); // distinct key verified on-device; the
// original section==key read ("GameOver","GameOver") is left untouched in the inis.
