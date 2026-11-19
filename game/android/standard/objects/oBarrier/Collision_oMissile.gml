// Ice Beam must freeze the barrier before a missile can shatter it and remove the solid wall.
if (frozen == 0) {
    wiggle = 45;
    with (other) event_user(1);
} else {
    event_user(0);
    with (other) event_user(0);
}

