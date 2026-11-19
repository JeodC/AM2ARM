flashing = 5;
with (oTester) {
    flashing = 6;
    if (enableforcefield == 0) {
        enableforcefield = 1;
        glass.enabled = 1;
    }
}
with (oTesterShield) flashing = 8;
with (oTesterCannon) flashing = 10;
// The eye owns the boss health and starts the body destruction sequence when it runs out.
if (myhealth <= 0) {
    make_explosion3(x, y);
    repeat (30) instance_create(x, y, oDebris);
    with (oTester) {
        state = 100;
        statetime = -1;
        alarm[10] = 1;
        alarm[11] = 300;
    }
    with (oTesterShield) event_user(1);
    visible = false;
}
sfx_stop(sndTesterHit);
sfx_play(sndTesterHit);

