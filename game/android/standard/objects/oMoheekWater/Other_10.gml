event_inherited();
// A surviving hit interrupts patrol and starts a fresh pursuit of Samus.
if (state != 100) {
    xVel *= 0.5;
    yVel *= 0.5;
    state = 1;
    statetime = 0;
}

