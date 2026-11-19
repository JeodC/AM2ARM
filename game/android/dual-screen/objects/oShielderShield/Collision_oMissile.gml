// The rotating shield has its own health, separate from the robot it protects.
with (other) event_user(0);
myhealth -= 14 * (1 + other.smissile * 5);
event_user(0);

