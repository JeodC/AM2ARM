/// @description  Input workaround for Linux

// Remember the axis positions after input handling so the next capture can ignore a held extreme.
for (var g = 0; g <= gamepad_axis_count(global.opjoyid); g ++) {
    linaxlast[g] = gamepad_axis_value(global.opjoyid, g);
}

