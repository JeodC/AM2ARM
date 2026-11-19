// Raise the temperature toward the target set by the next escape room, pausing during transitions.
if (global.ingame && room != rm_transition) {
    if (temp < gototemp) {
        temp += 1;
        alarm[0] = 20;
    }
} else alarm[0] = 1;

